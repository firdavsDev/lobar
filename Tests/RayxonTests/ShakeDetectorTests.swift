import Testing
import CoreGraphics
@testable import Rayxon

struct ShakeDetectorTests {
    @Test func rapidReversalsTriggerDizzy() {
        var d = ShakeDetector()
        var t = 0.0
        var fired = false
        for i in 0..<14 {
            let x = (i % 2 == 0) ? 0.0 : 120.0
            if d.record(point: CGPoint(x: x, y: 0), at: t) { fired = true }
            t += 0.08
        }
        #expect(fired)
    }

    @Test func slowSmoothDragDoesNotTrigger() {
        var d = ShakeDetector()
        var t = 0.0
        var fired = false
        for i in 0..<40 {
            if d.record(point: CGPoint(x: Double(i) * 10, y: 0), at: t) { fired = true }
            t += 0.05
        }
        #expect(!fired)
    }

    @Test func firesOnceThenCoolsDown() {
        var d = ShakeDetector()
        var t = 0.0
        var count = 0
        for i in 0..<40 {
            let x = (i % 2 == 0) ? 0.0 : 120.0
            if d.record(point: CGPoint(x: x, y: 0), at: t) { count += 1 }
            t += 0.08
        }
        #expect(count == 1)
    }
}
