import CoreGraphics

/// Detects rapid back-and-forth dragging. Fires once, then cools down.
struct ShakeDetector: Sendable {
    var window: Double = 1.5          // seconds of history
    var reversalsNeeded = 6
    var minSwing: Double = 30         // px of movement between reversals
    var cooldown: Double = 3

    private var samples: [(t: Double, x: Double)] = []
    private var lastFired: Double = -1e9

    /// Returns true when a shake is detected.
    mutating func record(point: CGPoint, at t: Double) -> Bool {
        samples.append((t, Double(point.x)))
        samples.removeAll { t - $0.t > window }
        guard t - lastFired > cooldown, samples.count >= 4 else { return false }
        var reversals = 0
        var dir = 0.0
        var anchor = samples[0].x
        for s in samples.dropFirst() {
            let d = s.x - anchor
            if abs(d) < minSwing { continue }
            let nd: Double = d > 0 ? 1 : -1
            if dir != 0, nd != dir { reversals += 1 }
            dir = nd
            anchor = s.x
        }
        if reversals >= reversalsNeeded {
            lastFired = t
            samples.removeAll()
            return true
        }
        return false
    }

    mutating func reset() { samples.removeAll() }
}
