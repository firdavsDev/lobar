import Testing
@testable import Rayxon

struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

struct BehaviorPlannerTests {
    @Test func producesIdleAndWalkWithDurationsInRange() {
        var rng = SeededRNG(state: 42)
        var sawIdle = false, sawWalk = false
        for _ in 0..<200 {
            switch BehaviorPlanner.nextAction(using: &rng) {
            case .idle(let d):
                sawIdle = true
                #expect(d >= 1.5 && d <= 6)
            case .walk(let dir, let d, let speed):
                sawWalk = true
                #expect(dir == 1 || dir == -1)
                #expect(d >= 1 && d <= 5)
                #expect(speed >= 45 && speed <= 70)
            case .activity(let state, let d):
                #expect(BehaviorPlanner.activities.contains(state))
                #expect(d >= 10 && d <= 30)
            }
        }
        #expect(sawIdle && sawWalk)
    }

    @Test func noActivitiesWhenNoneAvailable() {
        var rng = SeededRNG(state: 3)
        for _ in 0..<200 {
            if case .activity = BehaviorPlanner.nextAction(using: &rng, available: []) { Issue.record("activity without art") }
        }
    }

    @Test func edgeDecisionStepsOffAboutThirtyPercent() {
        var rng = SeededRNG(state: 7)
        var off = 0
        for _ in 0..<1000 where BehaviorPlanner.shouldStepOffEdge(using: &rng) { off += 1 }
        #expect(off > 200 && off < 400)
    }
}
