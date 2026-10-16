import AppKit

/// A round non falls from the top of the screen; the pet walks under it and catches it.
@MainActor
final class BreadDrop {
    private let window: NSWindow
    private var vy: Double = 0
    private var timer: Timer?
    private(set) var x: Double
    private var y: Double
    private let onCaught: () -> Void
    private let catchY: () -> Double
    private let petX: () -> Double

    init(x: Double, screen: NSScreen, petX: @escaping () -> Double, catchY: @escaping () -> Double, onCaught: @escaping () -> Void) {
        self.x = x
        self.y = Double(screen.visibleFrame.maxY) + 40
        self.petX = petX
        self.catchY = catchY
        self.onCaught = onCaught
        window = NSWindow(contentRect: NSRect(x: x - 22, y: y, width: 44, height: 44), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false; window.backgroundColor = .clear; window.hasShadow = false
        window.level = .floating; window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        let iv = NSImageView(frame: NSRect(x: 0, y: 0, width: 44, height: 44))
        iv.image = Self.nonImage(size: 44)
        window.contentView = iv
        window.orderFrontRegardless()
        let t = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in MainActor.assumeIsolated { self?.tick() } }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        vy -= 900 / 60.0
        vy = max(vy, -520)
        y += vy / 60.0
        let targetY = catchY()
        if y <= targetY {
            finish(); return
        }
        window.setFrameOrigin(NSPoint(x: x - 22, y: y))
        if y < targetY + 80, abs(petX() - x) > 30 { /* pet still walking; let it fall a bit more slowly */ vy = max(vy, -160) }
    }

    private func finish() {
        timer?.invalidate(); timer = nil
        window.orderOut(nil)
        onCaught()
    }

    static func nonImage(size: CGFloat) -> NSImage {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.lockFocus()
        let r = NSRect(x: 2, y: 2, width: size - 4, height: size - 4)
        NSColor(calibratedRed: 0.82, green: 0.58, blue: 0.28, alpha: 1).setFill(); NSBezierPath(ovalIn: r).fill()
        NSColor(calibratedRed: 0.62, green: 0.40, blue: 0.16, alpha: 1).setStroke()
        let rim = NSBezierPath(ovalIn: r.insetBy(dx: 3, dy: 3)); rim.lineWidth = 2.5; rim.stroke()
        NSColor(calibratedRed: 0.95, green: 0.80, blue: 0.50, alpha: 1).setFill()
        NSBezierPath(ovalIn: r.insetBy(dx: size * 0.3, dy: size * 0.3)).fill()
        NSColor(calibratedRed: 0.55, green: 0.33, blue: 0.12, alpha: 1).setFill()
        for i in 0..<8 {
            let a = Double(i) / 8 * 2 * .pi
            let p = NSPoint(x: r.midX + cos(a) * size * 0.12, y: r.midY + sin(a) * size * 0.12)
            NSBezierPath(ovalIn: NSRect(x: p.x - 1.2, y: p.y - 1.2, width: 2.4, height: 2.4)).fill()
        }
        img.unlockFocus()
        return img
    }
}
