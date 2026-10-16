import Foundation

enum PetState: String, CaseIterable, Sendable, Codable {
    case idle, walk, happy, dizzy, sleep, fall, land, talking, drag
    case drink, eat, stretch, eyes, annoyed
    case read, cook, lie, tea, dastarxon
}

struct SpriteAnimation: Codable, Equatable, Sendable {
    var frames: Int
    var fps: Double
    var loop: Bool
}

/// `{ outfit: { state: {frames, fps, loop} } }`
struct SpriteManifest: Sendable, Equatable {
    private let table: [String: [String: SpriteAnimation]]

    init(table: [String: [String: SpriteAnimation]]) { self.table = table }

    static func decode(_ data: Data) throws -> SpriteManifest {
        SpriteManifest(table: try JSONDecoder().decode([String: [String: SpriteAnimation]].self, from: data))
    }

    var outfits: [String] { table.keys.sorted() }

    func animation(outfit: String, state: PetState) -> SpriteAnimation? {
        table[outfit]?[state.rawValue]
    }

    func animationOrIdle(outfit: String, state: PetState) -> SpriteAnimation? {
        animation(outfit: outfit, state: state) ?? animation(outfit: outfit, state: .idle)
    }
}
