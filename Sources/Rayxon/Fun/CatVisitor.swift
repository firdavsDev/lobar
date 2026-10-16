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
        window = NSWindow(contentRect: NSRect(x: x, y: floorY, width: 56, height: 48), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false; window.backgroundColor = .clear; window.hasShadow = false
        window.level = .floating; window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 56, height: 48))
        let cfg = NSImage.SymbolConfiguration(pointSize: 36, weight: .regular)
        let img = NSImage(systemSymbolName: "cat.fill", accessibilityDescription: "mushuk")?.withSymbolConfiguration(cfg)
        imageView.image = img
        imageView.contentTintColor = NSColor(calibratedRed: 0.35, green: 0.30, blue: 0.28, alpha: 1)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        window.contentView = imageView
        window.orderFrontRegardless()
        let t = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in MainActor.assumeIsolated { self?.tick() } }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private var now: Double { CFAbsoluteTimeGetCurrent() }

    private func tick() {
        if let p = pausedUntil {
            if now >= p { pausedUntil = nil; leaving = true }
            return
        }
        let speed = 70.0 / 30
        phase += 0.25
        let bob = abs(sin(phase)) * 2
        if !leaving {
            x += dir * speed
            if (dir > 0 && x >= stopX) || (dir < 0 && x <= stopX) {
                pausedUntil = now + 6
                onArrive()
            }
        } else {
            x -= dir * speed
            let vf = window.screen?.visibleFrame ?? .zero
            if x < Double(vf.minX) - 80 || x > Double(vf.maxX) + 80 {
                timer?.invalidate(); timer = nil; window.orderOut(nil); onLeave(); return
            }
        }
        imageView.layer?.transform = CATransform3DIdentity
        let facingLeft = leaving ? dir > 0 : dir < 0
        imageView.layer?.setAffineTransform(facingLeft ? CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -56, y: 0) : .identity)
        window.setFrameOrigin(NSPoint(x: x, y: floorY + bob))
    }
    private var leaving = false
}
