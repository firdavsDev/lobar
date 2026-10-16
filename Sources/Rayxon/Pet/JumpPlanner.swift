import Foundation

/// Finds a nearby ledge to hop onto when the pet reaches the edge of her current window.
enum JumpPlanner {
    static let maxGap: Double = 140      // horizontal distance from edge to landing point
    static let maxRise: Double = 90      // how high she can jump
    static let maxDrop: Double = 260     // how far down she is willing to hop

    static func target(from here: Support, atX x: Double, direction: Double, candidates: [Support]) -> Support? {
        var best: (s: Support, cost: Double)?
        for c in candidates where c.id != here.id {
            // landing x: just inside the candidate's near edge
            let landX = direction > 0 ? c.minX + 20 : c.maxX - 20
            let dx = (landX - x) * direction
            guard dx > 10, dx <= maxGap else { continue }
            let dy = c.top - here.top
            guard dy <= maxRise, dy >= -maxDrop else { continue }
            guard c.contains(x: landX) else { continue }
            let cost = dx + max(0, dy) * 1.5 + max(0, -dy) * 0.3
            if best == nil || cost < best!.cost { best = (c, cost) }
        }
        return best?.s
    }

    /// Velocity so that a body under `gravity` travels (dx, dy) with a comfortable arc (apex ~ max(dy,0)+40).
    static func launchVelocity(dx: Double, dy: Double, gravity: Double) -> (vx: Double, vy: Double) {
        let apex = max(dy, 0) + 40
        let vy = (2 * gravity * apex).squareRoot()
        // time to rise to apex then fall to dy
        let tUp = vy / gravity
        let tDown = (2 * (apex - dy) / gravity).squareRoot()
        let t = tUp + tDown
        return (dx / t, vy)
    }
}
