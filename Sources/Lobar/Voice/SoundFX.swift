import AppKit

/// Short UI sounds from the system library (no bundled assets needed).
@MainActor
enum SoundFX {
    enum Kind { case pick, land, dizzy, happy, annoyed, done, sleep, wake }

    static var enabled: () -> Bool = { true }
    static var volume: () -> Double = { 0.5 }

    private static let names: [Kind: String] = [
        .pick: "Tink", .land: "Pop", .dizzy: "Basso", .happy: "Glass", .annoyed: "Funk", .done: "Hero", .sleep: "Blow", .wake: "Ping",
    ]

    static func play(_ kind: Kind) {
        guard enabled(), let name = names[kind], let s = NSSound(named: NSSound.Name(name)) else { return }
        s.volume = Float(volume())
        s.play()
    }
}
