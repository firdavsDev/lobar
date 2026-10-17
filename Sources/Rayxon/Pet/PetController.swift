import AppKit

/// Owns the pet window, the 30 Hz tick loop and the behavior state machine.
@MainActor
final class PetController {
    static let baseSize: CGFloat = 128
    private(set) var scale: Double = 1.0
    var size: CGFloat { Self.baseSize * scale }
    /// Distance from window bottom to the sprite's feet line (256px cell, feet at y=232 → 24px → 12pt @1x).
    var feetInset: Double { 12 * scale }

    enum Mode: Equatable {
        case idle(until: Double)
        case walking(direction: Double, speed: Double, until: Double)
        case falling
        case dragging
        case sleeping
        case happy(until: Double)
        case dizzy(until: Double)
        case talking
        case walkingToCursor
        case activity(PetState, until: Double)
        case walkingToEdge(direction: Double)
        case hiding(until: Double)
        case chasing(until: Double)
        case fetching(x: Double)
    }

    let window: PetWindow
    let view: PetView
    let animator = SpriteAnimator()
    let catalog: SpriteCatalog
    private(set) var outfit: String
    private(set) var body: Body
    private(set) var mode: Mode = .idle(until: 0)
    private(set) var support: SupportID? = .floor
    var supports: [Support] = []          // filled by WindowSurfaceProvider (phase 3)
    var onModeChange: ((Mode) -> Void)?
    var onRightClick: ((NSEvent, NSView) -> Void)?
    enum Event { case dragStarted, clicked, doubleClicked, dizzy, fellAndLanded, hardLanding, headPat, slept, woke, arrivedAtCursor, cursorNear, peekaboo, chaseFailed, chaseCaught, parachuteOpened }
    var funEnabled: () -> Bool = { true }
    static let hardLandingSpeed: Double = 1100
    var onEvent: ((Event) -> Void)?
    var onActivity: ((PetState) -> Void)?
    private var shake = ShakeDetector()
    private var fellFromWindow = false

    private var timer: Timer?
    private var lastTick = CFAbsoluteTimeGetCurrent()
    private var now: Double { CFAbsoluteTimeGetCurrent() }
    private var rng = SystemRandomNumberGenerator()

    // drag bookkeeping
    private var grabOffset = CGPoint.zero
    private var dragSamples: [(t: Double, p: CGPoint)] = []

    init(catalog: SpriteCatalog, outfit: String) {
        self.catalog = catalog
        self.outfit = outfit
        window = PetWindow(size: Self.baseSize)
        view = PetView(animator: animator, size: Self.baseSize)
        window.contentView = view
        animator.onParachute = { [weak view] on in view?.setParachute(on) }
        let floor = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        body = Body(x: floor.midX, y: floor.minY, vx: 0, vy: 0)
        view.controller = self
        applyBodyToWindow()
        play(.idle)
        window.orderFrontRegardless()
        startTimer()
    }

    // MARK: - Public controls

    func setScale(_ s: Double) {
        scale = max(0.4, min(2.5, s))
        window.setContentSize(NSSize(width: size, height: size * 2))
        view.frame = NSRect(x: 0, y: 0, width: size, height: size * 2)
        view.layoutProps()
        applyBodyToWindow()
    }

    /// Screen rect of the sprite square (window is taller to leave room for props above her).
    var spriteFrame: NSRect { NSRect(x: window.frame.minX, y: window.frame.minY, width: size, height: size) }

    func setOutfit(_ name: String) {
        outfit = name
        play(animator.state)
    }

    func sleep() { enter(.sleeping); onEvent?(.slept) }
    func hide() { window.orderOut(nil) }
    func show() { window.orderFrontRegardless() }
    var isHidden: Bool { !window.isVisible }
    func wake() { enter(.idle(until: now + 1)); onEvent?(.woke) }
    func headPat() { enter(.happy(until: now + 2.5)); onEvent?(.headPat) }
    func celebrate(seconds: Double = 2.5) { enter(.happy(until: now + seconds)) }
    /// Timed reaction pose; ignored while being dragged, falling or sleeping.
    func react(_ state: PetState, seconds: Double) {
        switch mode {
        case .dragging, .falling, .sleeping: return
        default: break
        }
        guard let (img, anim) = catalog.strip(outfit: outfit, state: state) else { return }
        mode = .activity(state, until: now + seconds)
        animator.play(img, animation: anim, state: state)
        onModeChange?(mode)
    }
    func comeToCursor() { enter(.walkingToCursor) }
    func setTalking(_ on: Bool) {
        if on { enter(.talking) } else if case .talking = mode { enter(.idle(until: now + 1)) }
    }
    func triggerDizzy() { pendingDizzy = true }
    private var pendingDizzy = false
    private var lostMouseUpTicks = 0
    private var walkRamp = 0.0
    private var jumping = false
    private var parachuting = false
    private var fallDistance = 0.0
    private var lastMouse = CGPoint.zero
    private var lastMouseT = 0.0
    private var chaseCooldownUntil = 0.0
    private var hideDir = 1.0
    private var walkPhase = 0.0
    private var bob = 0.0
    private var turnPauseUntil = 0.0

    /// Debug helper: lift the pet to `y` (feet line) and let her fall.
    func debugDrop(toY y: Double) {
        body.y = y; body.vx = 0; body.vy = 0
        applyBodyToWindow()
        enter(.falling)
    }

    var isSleeping: Bool { if case .sleeping = mode { return true } else { return false } }

    // MARK: - Mouse

    func mouseDown(_ e: NSEvent) {
        if e.clickCount == 2 { onEvent?(.doubleClicked); return }
        let p = NSEvent.mouseLocation
        grabOffset = CGPoint(x: p.x - window.frame.origin.x, y: p.y - window.frame.origin.y)
        dragSamples = [(now, p)]
        shake.reset()
        enter(.dragging)
        onEvent?(.dragStarted)
    }

    func mouseDragged(_ e: NSEvent) {
        let p = NSEvent.mouseLocation
        dragSamples.append((now, p))
        if dragSamples.count > 24 { dragSamples.removeFirst() }
        if shake.record(point: p, at: now) { onEvent?(.dizzy) }
        let minY = floorY - feetInset
        window.setFrameOrigin(NSPoint(x: p.x - grabOffset.x, y: max(minY, p.y - grabOffset.y)))
        body.x = window.frame.midX
        body.y = window.frame.minY + feetInset
    }

    func mouseUp(_ e: NSEvent?) {
        guard case .dragging = mode else { return }
        let moved = dragSamples.count > 1 && hypot(Double(dragSamples.last!.p.x - dragSamples.first!.p.x),
                                                   Double(dragSamples.last!.p.y - dragSamples.first!.p.y)) > 6
        if !moved { onEvent?(.clicked) }
        // throw velocity from the last ~100 ms of samples
        let t = now
        let recent = dragSamples.filter { t - $0.t < 0.12 }
        if let first = recent.first, let last = recent.last, last.t > first.t {
            let dt = last.t - first.t
            body.vx = Double(last.p.x - first.p.x) / dt
            body.vy = Double(last.p.y - first.p.y) / dt
            body.vx = max(-1500, min(1500, body.vx))
            body.vy = max(-1500, min(1500, body.vy))
        } else {
            body.vx = 0; body.vy = 0
        }
        dragSamples.removeAll()
        if Physics.support(under: body, supports: supports, floorY: floorY) != nil, body.vy <= 0 {
            body.vx = 0; body.vy = 0
            if pendingDizzy { pendingDizzy = false; enter(.dizzy(until: now + 3)) }
            else { enter(.idle(until: now + 1)) }
        } else {
            enter(.falling)
        }
    }

    func rightMouseDown(_ e: NSEvent, in view: NSView) { onRightClick?(e, view) }

    // MARK: - Tick

    private func startTimer() {
        let t = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private var floorY: Double {
        let screen = NSScreen.screens.first { $0.frame.contains(NSPoint(x: body.x, y: max(body.y, $0.frame.minY + 1))) }
            ?? NSScreen.main
        return Double(screen?.visibleFrame.minY ?? 0)
    }

    private var screenXRange: ClosedRange<Double> {
        let screen = NSScreen.screens.first { $0.frame.contains(NSPoint(x: body.x, y: body.y + 1)) } ?? NSScreen.main
        let f = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let half = Double(size) / 2
        let lo = Double(f.minX) + half, hi = Double(f.maxX) - half
        return hi > lo ? lo...hi : Double(f.midX)...Double(f.midX)
    }

    private func tick() {
        let t = now
        let dt = min(t - lastTick, 0.1)
        lastTick = t
        animator.tick(dt: dt)

        switch mode {
        case .dragging:
            // Safety net: if the mouse-up never reached us, drop her once the button is released.
            if NSEvent.pressedMouseButtons & 1 == 0 {
                lostMouseUpTicks += 1
                if lostMouseUpTicks > 6 { lostMouseUpTicks = 0; Log.pet.notice("mouseUp lost; dropping"); mouseUp(nil) }
            } else {
                lostMouseUpTicks = 0
            }
        case .sleeping, .talking:
            break

        case .falling:
            let keepVX = jumping ? body.vx : nil
            if parachuting { body.vy = max(body.vy, -200) }
            let impact = -body.vy
            if let landed = Physics.step(&body, dt: dt, supports: supports, floorY: floorY) {
                jumping = false
                if parachuting { parachuting = false; animator.setParachute(false) }
                support = landed
                body.vx = 0
                let hard = impact >= Self.hardLandingSpeed
                if pendingDizzy || hard { pendingDizzy = false; enter(.dizzy(until: t + (hard ? 2.5 : 3))) }
                else { enter(.idle(until: t + 0.6)); play(.land) }
                if hard { fellFromWindow = false; onEvent?(.hardLanding) }
                else if fellFromWindow { fellFromWindow = false; onEvent?(.fellAndLanded) }
            } else {
                if let keepVX { body.vx = keepVX }          // no air drag mid-jump
                if animator.state != .fall { play(.fall) }
                fallDistance += max(0, -body.vy * dt)
                if fellFromWindow, !parachuting, fallDistance > 120, funEnabled() {
                    parachuting = true
                    animator.setParachute(true)
                    body.vy = max(body.vy, -200)
                    onEvent?(.parachuteOpened)
                }
            }
            clampX()
            applyBodyToWindow()

        case .idle(let until):
            if animator.state == .land, animator.isFinished { play(.idle) }
            if !standing() { enter(.falling); return }
            lookAtCursor()
            if funEnabled(), t > chaseCooldownUntil, cursorIsDartingNearby(t) { enter(.chasing(until: t + 4)); return }
            if t >= until { plan() }

        case .walking(let direction, let speed, let until):
            if !standing() { enter(.falling); return }
            if t >= until { plan(); return }
            if turnPauseUntil > t { break }          // brief stop while turning around
            animator.setFacing(left: direction < 0)
            let ease = min(1, (until - t) * 2)        // slow down before stopping
            walkRamp = min(1, walkRamp + dt * 2.5)
            walkPhase += dt * speed / 28               // ~one stride per 28pt
            let wobble = 1 + 0.12 * sin(walkPhase * .pi * 2)   // feet push/glide rhythm
            walk(dx: direction * speed * walkRamp * ease * wobble * dt, canStepOff: true)
            bob = abs(sin(walkPhase * .pi * 2)) * 1.5 * scale
            applyBodyToWindow()

        case .walkingToCursor:
            if !standing() { enter(.falling); return }
            let target = Double(NSEvent.mouseLocation.x)
            let dx = target - body.x
            if abs(dx) < 10 { enter(.idle(until: t + 2)); onEvent?(.arrivedAtCursor); return }
            animator.setFacing(left: dx < 0)
            walk(dx: (dx < 0 ? -1 : 1) * 110 * dt, canStepOff: true)
            applyBodyToWindow()

        case .happy(let until), .dizzy(let until), .activity(_, let until):
            if !standing() { enter(.falling); return }
            if t >= until { enter(.idle(until: t + 1)) }

        case .walkingToEdge(let direction):
            if !standing() { enter(.falling); return }
            animator.setFacing(left: direction < 0)
            let r = screenXRange
            body.x += direction * 70 * dt
            if (direction > 0 && body.x >= r.upperBound) || (direction < 0 && body.x <= r.lowerBound) {
                // slide mostly off-screen, peek back inward
                body.x = direction > 0 ? r.upperBound + Double(size) * 0.62 : r.lowerBound - Double(size) * 0.62
                animator.setFacing(left: direction > 0)
                hideDir = direction
                enter(.hiding(until: t + Double.random(in: 8...18, using: &rng)))
            }
            applyBodyToWindow()

        case .hiding(let until):
            if t >= until {
                let r = screenXRange
                body.x = hideDir > 0 ? r.upperBound - 10 : r.lowerBound + 10
                applyBodyToWindow()
                enter(.happy(until: t + 2.5))
                onEvent?(.peekaboo)
            }

        case .chasing(let until):
            if !standing() { enter(.falling); return }
            let target = Double(NSEvent.mouseLocation.x)
            let dx = target - body.x
            if abs(dx) < 24 { enter(.happy(until: t + 2)); onEvent?(.chaseCaught); return }
            if t >= until { chaseCooldownUntil = t + 90; onEvent?(.chaseFailed); react(.tea, seconds: 5); return }
            animator.setFacing(left: dx < 0)
            walk(dx: (dx < 0 ? -1 : 1) * 170 * dt, canStepOff: false)
            applyBodyToWindow()

        case .fetching(let x):
            if !standing() { enter(.falling); return }
            let dx = x - body.x
            if abs(dx) < 10 { enter(.idle(until: t + 4)); return }     // wait under the bread
            animator.setFacing(left: dx < 0)
            walk(dx: (dx < 0 ? -1 : 1) * 150 * dt, canStepOff: false)
            applyBodyToWindow()
        }
    }

    /// Face the cursor when it is close; fire `.cursorNear` once when it hovers right over her.
    private var cursorNearSince: Double?
    private func lookAtCursor() {
        let p = NSEvent.mouseLocation
        let dx = Double(p.x) - body.x
        let near = abs(dx) < 220 && Double(p.y) > body.y - 20 && Double(p.y) < body.y + Double(size) + 40
        if near, abs(dx) > 12 { animator.setFacing(left: dx < 0) }
        let over = spriteFrame.insetBy(dx: -6, dy: -6).contains(p)
        if over {
            if cursorNearSince == nil { cursorNearSince = now }
            else if now - cursorNearSince! > 1.2 { cursorNearSince = .infinity; onEvent?(.cursorNear) }
        } else if cursorNearSince != nil, !over { cursorNearSince = nil }
    }

    /// Seconds since the user last moved the mouse / pressed a key (no permissions needed).
    static func secondsSinceUserInput() -> Double {
        let types: [CGEventType] = [.mouseMoved, .leftMouseDown, .rightMouseDown, .keyDown, .scrollWheel, .leftMouseDragged]
        return types.map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }.min() ?? 0
    }

    /// True if there is a support under the feet; also keeps the pet riding a moving support.
    private func standing() -> Bool {
        guard let id = Physics.support(under: body, supports: supports, floorY: floorY) else {
            if case .window = support ?? .floor { fellFromWindow = true }
            support = nil
            return false
        }
        if case .window = id, let s = supports.first(where: { $0.id == id }) {
            body.y = s.top
            applyBodyToWindow()
        } else if id == .floor {
            body.y = floorY
        }
        support = id
        return true
    }

    private func walk(dx: Double, canStepOff: Bool) {
        var nx = body.x + dx
        if support == .floor, Int.random(in: 0..<90, using: &rng) == 0 {
            let here = Support(id: .floor, top: floorY, minX: -1e9, maxX: 1e9)
            if let target = JumpPlanner.target(from: here, atX: body.x, direction: dx >= 0 ? 1 : -1, candidates: supports) {
                let landX = dx >= 0 ? target.minX + 20 : target.maxX - 20
                let v = JumpPlanner.launchVelocity(dx: landX - body.x, dy: target.top - body.y, gravity: Physics.gravity)
                body.vx = v.vx; body.vy = v.vy
                jumping = true
                enter(.falling)
                return
            }
        }
        if case .window(let n) = support ?? .floor, let s = supports.first(where: { $0.id == .window(n) }) {
            if nx < s.minX || nx > s.maxX {
                let dir: Double = nx > s.maxX ? 1 : -1
                let ledges = supports + [Support(id: .floor, top: floorY, minX: -1e9, maxX: 1e9)]
                if let target = JumpPlanner.target(from: s, atX: body.x, direction: dir, candidates: ledges),
                   target.id != .floor || Bool.random(using: &rng) {
                    let landX = dir > 0 ? target.minX + 20 : target.maxX - 20
                    let v = JumpPlanner.launchVelocity(dx: landX - body.x, dy: target.top - body.y, gravity: Physics.gravity)
                    body.vx = v.vx; body.vy = v.vy
                    jumping = true
                    animator.setFacing(left: dir < 0)
                    enter(.falling)
                    return
                }
                if canStepOff, BehaviorPlanner.shouldStepOffEdge(using: &rng) {
                    body.x = nx
                    fellFromWindow = true
                    enter(.falling)
                    return
                }
                // turn around after a tiny pause
                nx = min(max(nx, s.minX), s.maxX)
                if case .walking(let d, let sp, let until) = mode {
                    mode = .walking(direction: -d, speed: sp, until: until)
                    turnPauseUntil = now + 0.35
                    walkRamp = 0
                }
            }
        }
        body.x = nx
        clampX()
    }

    private func clampX() {
        let r = screenXRange
        var hit = false
        if body.x < r.lowerBound { body.x = r.lowerBound; body.vx = 0; hit = true }
        if body.x > r.upperBound { body.x = r.upperBound; body.vx = 0; hit = true }
        if hit, case .walking(let d, let sp, let until) = mode {
            mode = .walking(direction: -d, speed: sp, until: until)
            turnPauseUntil = now + 0.35
            walkRamp = 0
        }
    }

    private func cursorIsDartingNearby(_ t: Double) -> Bool {
        let p = NSEvent.mouseLocation
        defer { lastMouse = p; lastMouseT = t }
        guard lastMouseT > 0, t - lastMouseT < 0.2 else { return false }
        let speed = hypot(Double(p.x - lastMouse.x), Double(p.y - lastMouse.y)) / (t - lastMouseT)
        let near = abs(Double(p.x) - body.x) < 420 && abs(Double(p.y) - body.y) < 260
        let over = spriteFrame.insetBy(dx: -10, dy: -10).contains(p)
        return speed > 900 && near && !over
    }

    /// Public hooks for fun events
    func startHide() { let r = screenXRange; enter(.walkingToEdge(direction: body.x > (r.lowerBound + r.upperBound) / 2 ? 1 : -1)) }
    func fetch(x: Double) { if case .dragging = mode { return }; enter(.fetching(x: x)) }
    var headY: Double { body.y + Double(size) * 0.78 }
    var currentScreen: NSScreen? { window.screen ?? NSScreen.main }

    private func plan() {
        if funEnabled(), support == .floor, Int.random(in: 0..<22, using: &rng) == 0 { startHide(); return }
        let available = BehaviorPlanner.activities.filter { catalog.manifest.animation(outfit: outfit, state: $0) != nil }
        switch BehaviorPlanner.nextAction(using: &rng, available: available) {
        case .idle(let d): enter(.idle(until: now + d))
        case .walk(let dir, let d, let speed): enter(.walking(direction: dir, speed: speed, until: now + d))
        case .activity(let a, let d):
            enter(.activity(a, until: now + d))
            onActivity?(a)
        }
    }

    private func enter(_ new: Mode) {
        Log.pet.debug("mode → \(String(describing: new))")
        mode = new
        switch new {
        case .idle: bob = 0; if animator.state != .land { play(.idle) }
        case .walking: walkRamp = 0; play(.walk)
        case .falling: fallDistance = 0; play(.fall)
        case .walkingToEdge: play(.walk)
        case .hiding: play(.idle)
        case .chasing: play(.walk)
        case .fetching: play(.walk)
        case .dragging: play(.drag)
        case .sleeping: animator.setFacing(left: false); play(catalog.manifest.animation(outfit: outfit, state: .lie) != nil ? .lie : .sleep)
        case .happy: play(.happy)
        case .dizzy: play(.dizzy)
        case .talking: play(.talking)
        case .walkingToCursor: play(.walk)
        case .activity(let a, _): animator.setFacing(left: false); play(a)
        }
        onModeChange?(new)
    }

    func play(_ state: PetState) {
        guard let (img, anim) = catalog.strip(outfit: outfit, state: state) else { return }
        animator.play(img, animation: anim, state: state)
    }

    private func applyBodyToWindow() {
        window.setFrameOrigin(NSPoint(x: body.x - Double(size) / 2, y: body.y - feetInset + bob))
    }
}
