import CoreGraphics

/// Pure frame-stepping clock for a horizontal sprite strip.
struct FrameClock: Sendable, Equatable {
    var fps: Double
    var frameCount: Int
    var loop: Bool
    private(set) var frameIndex: Int = 0
    private var accumulator: Double = 0

    init(fps: Double, frameCount: Int, loop: Bool) {
        self.fps = fps
        self.frameCount = max(1, frameCount)
        self.loop = loop
    }

    var isFinished: Bool { !loop && frameIndex == frameCount - 1 }

    /// Normalized rect of the current frame inside the strip (for CALayer.contentsRect).
    var contentsRect: CGRect {
        let w = 1.0 / Double(frameCount)
        return CGRect(x: w * Double(frameIndex), y: 0, width: w, height: 1)
    }

    /// Advances by `dt` seconds. Returns true when the visible frame changed.
    @discardableResult
    mutating func advance(dt: Double) -> Bool {
        guard frameCount > 1, fps > 0, !isFinished else { return false }
        accumulator += dt
        let period = 1.0 / fps
        var changed = false
        while accumulator >= period - 1e-9 {
            accumulator -= period
            if frameIndex + 1 < frameCount {
                frameIndex += 1
                changed = true
            } else if loop {
                frameIndex = 0
                changed = true
            } else {
                accumulator = 0
                break
            }
        }
        return changed
    }

    mutating func reset() {
        frameIndex = 0
        accumulator = 0
    }
}
