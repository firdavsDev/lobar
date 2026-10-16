import Foundation

/// Pet body in AppKit screen coordinates (bottom-left origin). `y` is the feet line.
struct Body: Equatable, Sendable {
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
}

enum SupportID: Equatable, Hashable, Sendable {
    case floor
    case window(Int)
}

/// A horizontal top edge the pet can stand on.
struct Support: Equatable, Sendable {
    var id: SupportID
    var top: Double
    var minX: Double
    var maxX: Double

    func contains(x: Double) -> Bool { x >= minX && x <= maxX }
}

enum Physics {
    static let gravity: Double = 2400
    static let maxFallSpeed: Double = 1800
    static let airDrag: Double = 3.0        // per second, exponential
    static let standTolerance: Double = 4

    /// Integrates one step. Returns the support landed on this step, if any.
    @discardableResult
    static func step(_ body: inout Body, dt: Double, supports: [Support], floorY: Double) -> SupportID? {
        let oldY = body.y
        if body.y <= floorY, body.vy <= 0 {           // already at/below the floor (e.g. dragged there)
            body.y = floorY; body.vy = 0
            body.vx *= exp(-airDrag * dt); body.x += body.vx * dt
            return .floor
        }
        body.vy = max(body.vy - gravity * dt, -maxFallSpeed)
        body.vx *= exp(-airDrag * dt)
        body.x += body.vx * dt
        body.y += body.vy * dt
        guard body.vy < 0 else { return nil }

        // Highest support whose top edge was crossed between oldY and the new y.
        var best: (id: SupportID, top: Double)? = (.floor, floorY)
        if !(floorY <= oldY && floorY >= body.y) { best = nil }
        for s in supports where s.contains(x: body.x) && s.top <= oldY + 0.001 && s.top >= body.y {
            if best == nil || s.top > best!.top { best = (s.id, s.top) }
        }
        guard let hit = best else { return nil }
        body.y = hit.top
        body.vy = 0
        return hit.id
    }

    /// Which support is directly under the feet right now (within tolerance).
    static func support(under body: Body, supports: [Support], floorY: Double) -> SupportID? {
        var best: (id: SupportID, top: Double)?
        for s in supports where s.contains(x: body.x) && abs(s.top - body.y) <= standTolerance {
            if best == nil || s.top > best!.top { best = (s.id, s.top) }
        }
        if best == nil, abs(floorY - body.y) <= standTolerance { return .floor }
        return best?.id
    }
}
