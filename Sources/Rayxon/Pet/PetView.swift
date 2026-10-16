import AppKit

/// Hosts the sprite layer and forwards mouse events to the controller.
@MainActor
final class PetView: NSView {
    let animator: SpriteAnimator
    weak var controller: PetController?

    init(animator: SpriteAnimator, size: CGFloat) {
        self.animator = animator
        super.init(frame: NSRect(x: 0, y: 0, width: size, height: size))
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        animator.layer.frame = bounds
        animator.layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer?.addSublayer(animator.layer)
    }

    required init?(coder: NSCoder) { nil }

    override var isFlipped: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        return animator.alpha(at: local, in: bounds) > 0.05 ? self : nil
    }

    override func mouseDown(with event: NSEvent) { controller?.mouseDown(event) }
    override func mouseDragged(with event: NSEvent) { controller?.mouseDragged(event) }
    override func mouseUp(with event: NSEvent) { controller?.mouseUp(event) }
    override func rightMouseDown(with event: NSEvent) { controller?.rightMouseDown(event, in: self) }
}
