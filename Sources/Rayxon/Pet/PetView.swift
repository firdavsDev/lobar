import AppKit

/// Hosts the sprite layer and forwards mouse events to the controller.
@MainActor
final class PetView: NSView {
    let animator: SpriteAnimator
    weak var controller: PetController?

    let parachute = CALayer()
    let handProp = CALayer()

    init(animator: SpriteAnimator, size: CGFloat) {
        self.animator = animator
        super.init(frame: NSRect(x: 0, y: 0, width: size, height: size * 2))
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        animator.layer.frame = CGRect(x: 0, y: 0, width: size, height: size)
        layer?.addSublayer(animator.layer)
        parachute.contents = Props.cgImage("parachute")
        parachute.contentsGravity = .resizeAspect
        parachute.isHidden = true
        parachute.zPosition = 5
        layer?.addSublayer(parachute)
        handProp.contentsGravity = .resizeAspect
        handProp.isHidden = true
        handProp.zPosition = 6
        layer?.addSublayer(handProp)
        layoutProps()
    }

    /// Shows/hides a prop held above the head (umbrella).
    func setHandProp(_ image: CGImage?) {
        CATransaction.begin(); CATransaction.setDisableActions(true)
        handProp.contents = image
        handProp.isHidden = image == nil
        CATransaction.commit()
    }

    /// Square the sprite lives in (bottom of the view).
    var spriteRect: CGRect { CGRect(x: 0, y: 0, width: bounds.width, height: bounds.width) }

    func layoutProps() {
        let s = bounds.width
        animator.layer.frame = CGRect(x: 0, y: 0, width: s, height: s)
        parachute.frame = CGRect(x: s * 0.02, y: s * 0.72, width: s * 0.96, height: s * 1.2)
        handProp.frame = CGRect(x: s * 0.12, y: s * 0.62, width: s * 0.9, height: s * 0.75)
    }

    func setParachute(_ on: Bool) {
        CATransaction.begin(); CATransaction.setDisableActions(true)
        parachute.isHidden = !on
        CATransaction.commit()
    }

    required init?(coder: NSCoder) { nil }

    override var isFlipped: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        guard spriteRect.contains(local) else { return nil }
        return animator.alpha(at: local, in: spriteRect) > 0.05 ? self : nil
    }

    override func mouseDown(with event: NSEvent) { controller?.mouseDown(event) }
    override func mouseDragged(with event: NSEvent) { controller?.mouseDragged(event) }
    override func mouseUp(with event: NSEvent) { controller?.mouseUp(event) }
    override func rightMouseDown(with event: NSEvent) { controller?.rightMouseDown(event, in: self) }
}
