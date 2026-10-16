import AppKit
import QuartzCore

/// Drives a CALayer from a sprite strip using FrameClock.
@MainActor
final class SpriteAnimator {
    let layer = CALayer()
    let sleepEffect = SleepEffectLayer()
    let parachute = CAShapeLayer()
    private(set) var clock = FrameClock(fps: 1, frameCount: 1, loop: true)
    private(set) var state: PetState = .idle
    private(set) var facingLeft = false
    private var currentImage: CGImage?

    init() {
        layer.contentsGravity = .resizeAspect
        layer.magnificationFilter = .linear
        layer.minificationFilter = .trilinear
        layer.isGeometryFlipped = false
        sleepEffect.frame = CGRect(x: 0, y: 0, width: 128, height: 128)
        sleepEffect.zPosition = 10
        layer.addSublayer(sleepEffect)
        parachute.fillColor = NSColor(calibratedRed: 0.95, green: 0.45, blue: 0.55, alpha: 0.95).cgColor
        parachute.strokeColor = NSColor(calibratedRed: 0.55, green: 0.2, blue: 0.3, alpha: 1).cgColor
        parachute.lineWidth = 1.5
        parachute.isHidden = true
        parachute.zPosition = 5
        layer.addSublayer(parachute)
    }

    func setParachute(_ on: Bool) {
        guard parachute.isHidden == on else { return }
        let w = layer.bounds.width, h = layer.bounds.height
        let p = CGMutablePath()
        let top = h * 1.35, cx = w / 2, r = w * 0.42
        p.addArc(center: CGPoint(x: cx, y: top - r * 0.2), radius: r, startAngle: 0, endAngle: .pi, clockwise: false)
        p.closeSubpath()
        // lines to shoulders
        for dx in [-r, -r / 3, r / 3, r] {
            p.move(to: CGPoint(x: cx + dx, y: top - r * 0.2))
            p.addLine(to: CGPoint(x: cx + dx * 0.25, y: h * 0.72))
        }
        parachute.path = p
        parachute.isHidden = !on
    }

    func play(_ image: CGImage, animation: SpriteAnimation, state: PetState) {
        self.state = state
        if state == .sleep || state == .lie {
            // anchor the z's above the head: for lying pose the head is low-left
            sleepEffect.frame = state == .lie
                ? CGRect(x: layer.bounds.width * 0.15, y: layer.bounds.height * 0.35, width: 20, height: 20)
                : CGRect(x: layer.bounds.width * 0.55, y: layer.bounds.height * 0.78, width: 20, height: 20)
            sleepEffect.start()
        } else {
            sleepEffect.stop()
        }
        currentImage = image
        clock = FrameClock(fps: animation.fps, frameCount: animation.frames, loop: animation.loop)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.contents = image
        layer.contentsRect = clock.contentsRect
        CATransaction.commit()
    }

    func setFacing(left: Bool) {
        guard left != facingLeft else { return }
        facingLeft = left
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.transform = left ? CATransform3DMakeScale(-1, 1, 1) : CATransform3DIdentity
        sleepEffect.transform = left ? CATransform3DMakeScale(-1, 1, 1) : CATransform3DIdentity
        CATransaction.commit()
    }

    var isFinished: Bool { clock.isFinished }

    func tick(dt: Double) {
        if clock.advance(dt: dt) {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.contentsRect = clock.contentsRect
            CATransaction.commit()
        }
    }

    /// Alpha at a point in layer coordinates (bottom-left origin); used for hit testing.
    func alpha(at point: CGPoint, in bounds: CGRect) -> CGFloat {
        guard let img = currentImage else { return 0 }
        let frameW = CGFloat(img.width) / CGFloat(clock.frameCount)
        let frameH = CGFloat(img.height)
        // layer draws aspect-fit; our cells are square and bounds square → direct scale
        var px = point.x / bounds.width * frameW
        if facingLeft { px = frameW - px }
        let py = (1 - point.y / bounds.height) * frameH
        let x = Int(CGFloat(clock.frameIndex) * frameW + px)
        let y = Int(py)
        guard x >= 0, y >= 0, x < img.width, y < img.height,
              let data = img.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 0 }
        let bpp = img.bitsPerPixel / 8
        let offset = y * img.bytesPerRow + x * bpp
        let alphaInfo = img.alphaInfo
        switch alphaInfo {
        case .premultipliedFirst, .first: return CGFloat(ptr[offset]) / 255
        case .premultipliedLast, .last: return CGFloat(ptr[offset + bpp - 1]) / 255
        default: return 1
        }
    }
}
