import Foundation

enum Games {
    enum RPS: String, CaseIterable, Sendable { case rock = "Tosh", paper = "Qog'oz", scissors = "Qaychi"
        var emoji: String { switch self { case .rock: return "🪨"; case .paper: return "📄"; case .scissors: return "✂️" } }
    }
    enum Outcome: Sendable { case userWins, petWins, draw }
    enum Hand: Sendable { case left, right }

    static func rps(user: RPS, pet: RPS) -> Outcome {
        if user == pet { return .draw }
        switch (user, pet) {
        case (.rock, .scissors), (.paper, .rock), (.scissors, .paper): return .userWins
        default: return .petWins
        }
    }

    static func randomRPS<G: RandomNumberGenerator>(using rng: inout G) -> RPS { RPS.allCases.randomElement(using: &rng)! }
    static func hideHand<G: RandomNumberGenerator>(using rng: inout G) -> Hand { Bool.random(using: &rng) ? .left : .right }
}
