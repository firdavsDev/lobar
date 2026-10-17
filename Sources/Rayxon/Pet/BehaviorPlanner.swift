import Foundation

enum PlannedAction: Equatable, Sendable {
    case idle(duration: Double)
    case walk(direction: Double, duration: Double, speed: Double)
    case activity(PetState, duration: Double)
}

/// Pure random decision table for idle behavior.
enum BehaviorPlanner {
    static let activities: [PetState] = [.read, .cook, .lie, .tea, .dastarxon]

    static func nextAction<G: RandomNumberGenerator>(using rng: inout G, available: [PetState] = activities) -> PlannedAction {
        let r = Double.random(in: 0..<1, using: &rng)
        if r < 0.45 {
            return .idle(duration: Double.random(in: 1.5...6, using: &rng))
        }
        if r < 0.62, let a = available.randomElement(using: &rng) {
            return .activity(a, duration: Double.random(in: 10...30, using: &rng))
        }
        let dir: Double = Bool.random(using: &rng) ? 1 : -1
        return .walk(direction: dir,
                     duration: Double.random(in: 1...5, using: &rng),
                     speed: Double.random(in: 45...70, using: &rng))
    }

    static func shouldStepOffEdge<G: RandomNumberGenerator>(using rng: inout G) -> Bool {
        Double.random(in: 0..<1, using: &rng) < 0.3
    }
}
