import AppKit

/// A static prop placed on the floor near the pet for a while (snowman, cake, gift).
@MainActor
final class FloorProp {
    private let window: NSWindow
    private var timer: Timer?
    private var onDone: (() -> Void)?

    init(image: NSImage, x: Double, screen: NSScreen, height: CGFloat = 72, seconds: TimeInterval, onDone: @escaping () -> Void) {
        let ratio = image.size.width / max(image.size.height, 1)
        let w = height * ratio
        window = NSWindow(contentRect: NSRect(x: x - w / 2, y: screen.visibleFrame.minY, width: w, height: height),
                          styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false; window.backgroundColor = .clear; window.hasShadow = false
        window.level = .floating; window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        let iv = NSImageView(frame: NSRect(x: 0, y: 0, width: w, height: height))
        iv.image = image; iv.imageScaling = .scaleProportionallyUpOrDown
        window.contentView = iv
        window.alphaValue = 0
        window.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in ctx.duration = 0.6; window.animator().alphaValue = 1 }
        self.onDone = onDone
        let t = Timer(timeInterval: seconds, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.dismiss() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func dismiss() {
        timer?.invalidate(); timer = nil
        let w = window
        NSAnimationContext.runAnimationGroup { ctx in ctx.duration = 0.6; w.animator().alphaValue = 0 }
        // completion runs on main after the fade; keep the callback on the main actor via a timer
        let t = Timer(timeInterval: 0.65, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { w.orderOut(nil); let d = self?.onDone; self?.onDone = nil; d?() }
        }
        RunLoop.main.add(t, forMode: .common)
    }
}
