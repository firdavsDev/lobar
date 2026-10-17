import AppKit

/// A small cat (SF Symbol) strolls along the floor, pauses near the pet, then leaves.
@MainActor
final class CatVisitor {
    private let window: NSWindow
    private var x: Double
    private let dir: Double
    private let floorY: Double
    private let stopX: Double
    private var timer: Timer?
    private var pausedUntil: Double?
    private var phase = 0.0
    private let onArrive: () -> Void
    private let onLeave: () -> Void
    private let imageView: NSImageView

    init(screen: NSScreen, petX: Double, onArrive: @escaping () -> Void, onLeave: @escaping () -> Void) {
        let vf = screen.visibleFrame
        dir = petX > vf.midX ? 1 : -1
        x = dir > 0 ? Double(vf.minX) - 60 : Double(vf.maxX) + 60
        stopX = petX - dir * 70
        floorY = Double(vf.minY)
        self.onArrive = onArrive; self.onLeave = onLeave
        window = NSWindow(contentRect: NSRect(x: x, y: floorY, width: 64, height: 56), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false; window.backgroundColor = .clear; window.hasShadow = false
        window.level = .floating; window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 64, height: 56))
        if let img = Props.image("cat_walk") {
            imageView.image = img
        } else {
            let cfg = NSImage.SymbolConfiguration(pointSize: 36, weight: .regular)
            imageView.image = NSImage(systemSymbolName: "cat.fill", accessibilityDescription: "mushuk")?.withSymbolConfiguration(cfg)
            imageView.contentTintColor = NSColor(calibratedRed: 0.35, green: 0.30, blue: 0.28, alpha: 1)
        }
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        window.contentView = imageView
        window.orderFrontRegardless()
        let t = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in MainActor.assumeIsolated { self?.tick() } }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private var now: Double { CFAbsoluteTimeGetCurrent() }

    private func tick() {
        if let p = pausedUntil {
            if now >= p { pausedUntil = nil; leaving = true; if let w = Props.image("cat_walk") { imageView.image = w } }
            return
        }
        let speed = 70.0 / 30
        phase += 0.25
        let bob = abs(sin(phase)) * 2
        if !leaving {
            x += dir * speed
            if (dir > 0 && x >= stopX) || (dir < 0 && x <= stopX) {
                pausedUntil = now + 6
                if let sit = Props.image("cat_sit") { imageView.image = sit }
                onArrive()
            }
        } else {
            x -= dir * speed
            let vf = window.screen?.visibleFrame ?? .zero
            if x < Double(vf.minX) - 80 || x > Double(vf.maxX) + 80 {
                timer?.invalidate(); timer = nil; window.orderOut(nil); onLeave(); return
            }
        }
        let facingLeft = leaving ? dir > 0 : dir < 0
        imageView.layer?.setAffineTransform(facingLeft ? CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -64, y: 0) : .identity)
        window.setFrameOrigin(NSPoint(x: x, y: floorY + bob))
    }
    private var leaving = false
}
