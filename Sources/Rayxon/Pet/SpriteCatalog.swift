import AppKit

/// Loads sprite strips + manifest from the resource bundle and caches CGImages.
@MainActor
final class SpriteCatalog {
    let manifest: SpriteManifest
    private var cache: [String: CGImage] = [:]
    private let root: URL

    init() throws {
        let root = Bundle.module.resourceURL!.appendingPathComponent("Resources/Sprites")
        self.root = root
        let data = try Data(contentsOf: root.appendingPathComponent("manifest.json"))
        self.manifest = try SpriteManifest.decode(data)
    }

    /// Outfits that have real art (marked by a reference.jpg next to the strips).
    var outfits: [String] {
        let real = manifest.outfits.filter {
            FileManager.default.fileExists(atPath: root.appendingPathComponent("\($0)/reference.jpg").path)
        }
        return real.isEmpty ? manifest.outfits : real
    }

    static let outfitTitles: [String: String] = [
        "atlas": "Atlas — xonatlas ko'ylak",
        "adras": "Adras — chopon va do'ppi",
        "bahor": "Bahor — pushti gulli atlas",
        "tungi": "Tungi — to'q zardo'zi",
    ]

    func title(for outfit: String) -> String { Self.outfitTitles[outfit] ?? outfit.capitalized }

    /// Returns (strip image, animation). Falls back to idle if the state has no strip.
    func strip(outfit: String, state: PetState) -> (CGImage, SpriteAnimation)? {
        let resolved: PetState = manifest.animation(outfit: outfit, state: state) != nil ? state : .idle
        guard let anim = manifest.animation(outfit: outfit, state: resolved) else { return nil }
        let key = "\(outfit)/\(resolved.rawValue)"
        if let img = cache[key] { return (img, anim) }
        let url = root.appendingPathComponent("\(outfit)/\(resolved.rawValue).png")
        guard let nsimg = NSImage(contentsOf: url),
              let cg = nsimg.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        cache[key] = cg
        return (cg, anim)
    }
}
