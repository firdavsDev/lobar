import Testing
@testable import Lobar

struct PhysicsTests {
    @Test func gravityAcceleratesDownward() {
        var body = Body(x: 0, y: 500, vx: 0, vy: 0)
        let landed = Physics.step(&body, dt: 0.1, supports: [], floorY: 0)
        #expect(landed == nil)
        #expect(body.vy < 0)
        #expect(body.y < 500)
    }

    @Test func landsOnFloorAndStops() {
        var body = Body(x: 0, y: 5, vx: 0, vy: -600)
        let landed = Physics.step(&body, dt: 0.1, supports: [], floorY: 0)
        #expect(landed == .floor)
        #expect(body.y == 0)
        #expect(body.vy == 0)
    }

    @Test func landsOnHighestCrossedSupport() {
        var body = Body(x: 50, y: 100, vx: 0, vy: -1000)
        let s1 = Support(id: .window(1), top: 80, minX: 0, maxX: 100)
        let s2 = Support(id: .window(2), top: 40, minX: 0, maxX: 100)
        let landed = Physics.step(&body, dt: 0.1, supports: [s2, s1], floorY: 0)
        #expect(landed == .window(1))
        #expect(body.y == 80)
    }

    @Test func ignoresSupportsNotUnderFeet() {
        var body = Body(x: 500, y: 100, vx: 0, vy: -1000)
        let s1 = Support(id: .window(1), top: 80, minX: 0, maxX: 100)
        let landed = Physics.step(&body, dt: 0.1, supports: [s1], floorY: 0)
        #expect(landed == .floor)
        #expect(body.y == 0)
    }

    @Test func supportUnderFeetWithinTolerance() {
        let s = Support(id: .window(7), top: 80, minX: 0, maxX: 100)
        #expect(Physics.support(under: Body(x: 50, y: 82, vx: 0, vy: 0), supports: [s], floorY: 0) == .window(7))
        #expect(Physics.support(under: Body(x: 50, y: 90, vx: 0, vy: 0), supports: [s], floorY: 0) == nil)
        #expect(Physics.support(under: Body(x: 50, y: 1, vx: 0, vy: 0), supports: [], floorY: 0) == .floor)
    }

    @Test func horizontalVelocityDampsWhileAirborne() {
        var body = Body(x: 0, y: 500, vx: 100, vy: 0)
        _ = Physics.step(&body, dt: 0.1, supports: [], floorY: 0)
        #expect(body.x > 0)
        #expect(body.vx < 100)
    }
}
