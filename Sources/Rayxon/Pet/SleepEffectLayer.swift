import QuartzCore
import AppKit

/// Floating "z" letters rising above the head while sleeping.
final class SleepEffectLayer: CALayer {
    private var running = false

    func start() {
        guard !running else { return }
        running = true
        for i in 0..<3 { spawn(delay: Double(i) * 0.9) }
    }

    func stop() {
        running = false
        sublayers?.forEach { $0.removeAllAnimations() }
        sublayers = nil
    }

    private func spawn(delay: Double) {
        let z = CATextLayer()
        z.string = "z"
        z.font = NSFont.systemFont(ofSize: 14, weight: .heavy)
        z.fontSize = 14
        z.foregroundColor = NSColor(calibratedRed: 0.45, green: 0.40, blue: 0.85, alpha: 1).cgColor
        z.alignmentMode = .center
        z.contentsScale = 2
        z.frame = CGRect(x: bounds.midX - 8, y: bounds.midY - 8, width: 20, height: 18)
        z.opacity = 0
        addSublayer(z)

        let path = CAKeyframeAnimation(keyPath: "position")
        let start = CGPoint(x: bounds.midX + 4, y: bounds.minY)
        let p = CGMutablePath()
        p.move(to: start)
        p.addCurve(to: CGPoint(x: start.x + 18, y: start.y + 44),
                   control1: CGPoint(x: start.x + 14, y: start.y + 12),
                   control2: CGPoint(x: start.x - 2, y: start.y + 30))
        path.path = p
        let fade = CAKeyframeAnimation(keyPath: "opacity")
        fade.values = [0, 1, 1, 0]
        fade.keyTimes = [0, 0.15, 0.7, 1]
        let grow = CABasicAnimation(keyPath: "transform.scale")
        grow.fromValue = 0.6; grow.toValue = 1.4
        let group = CAAnimationGroup()
        group.animations = [path, fade, grow]
        group.duration = 2.7
        group.beginTime = CACurrentMediaTime() + delay
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        z.add(group, forKey: "float")
    }
}
