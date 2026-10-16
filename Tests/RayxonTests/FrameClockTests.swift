import Testing
import CoreGraphics
@testable import Rayxon

struct FrameClockTests {
    @Test func advancesOneFrameAfterOneFramePeriod() {
        var clock = FrameClock(fps: 10, frameCount: 4, loop: true)
        #expect(clock.frameIndex == 0)
        #expect(clock.advance(dt: 0.05) == false)
        #expect(clock.advance(dt: 0.05) == true)
        #expect(clock.frameIndex == 1)
    }

    @Test func loopsBackToZero() {
        var clock = FrameClock(fps: 10, frameCount: 2, loop: true)
        _ = clock.advance(dt: 0.1)
        _ = clock.advance(dt: 0.1)
        #expect(clock.frameIndex == 0)
    }

    @Test func nonLoopingClampsAtLastFrame() {
        var clock = FrameClock(fps: 10, frameCount: 2, loop: false)
        _ = clock.advance(dt: 0.1)
        _ = clock.advance(dt: 0.1)
        _ = clock.advance(dt: 0.1)
        #expect(clock.frameIndex == 1)
        #expect(clock.isFinished)
    }

    @Test func contentsRectSlicesHorizontalStrip() {
        var clock = FrameClock(fps: 10, frameCount: 4, loop: true)
        _ = clock.advance(dt: 0.2)
        #expect(clock.frameIndex == 2)
        #expect(clock.contentsRect == CGRect(x: 0.5, y: 0, width: 0.25, height: 1))
    }
}
