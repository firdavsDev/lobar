import Testing
@testable import Rayxon

struct JumpPlannerTests {
    @Test func findsReachableLedgeInWalkDirection() {
        let here = Support(id: .window(1), top: 300, minX: 0, maxX: 400)
        let near = Support(id: .window(2), top: 340, minX: 460, maxX: 800)     // 60pt gap, 40pt up → reachable
        let far = Support(id: .window(3), top: 300, minX: 900, maxX: 1200)     // too far
        let target = JumpPlanner.target(from: here, atX: 395, direction: 1, candidates: [far, near])
        #expect(target?.id == .window(2))
    }

    @Test func noLedgeMeansNoJump() {
        let here = Support(id: .window(1), top: 300, minX: 0, maxX: 400)
        let high = Support(id: .window(2), top: 600, minX: 420, maxX: 800)     // too high
        #expect(JumpPlanner.target(from: here, atX: 395, direction: 1, candidates: [high]) == nil)
    }

    @Test func launchVelocityLandsOnTarget() {
        let v = JumpPlanner.launchVelocity(dx: 100, dy: 40, gravity: 2400)
        // simulate
        var x = 0.0, y = 0.0, vx = v.vx, vy = v.vy
        let dt = 1.0 / 240
        var landedNear = false
        for _ in 0..<2000 {
            vy -= 2400 * dt; x += vx * dt; y += vy * dt
            if vy < 0, y <= 40 { landedNear = abs(x - 100) < 8; break }
        }
        #expect(landedNear)
    }
}
