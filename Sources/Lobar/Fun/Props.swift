import AppKit

/// Prop images generated with the character sheets (Resources/Props/*.png).
enum Props {
    static func image(_ name: String) -> NSImage? {
        guard let root = Bundle.module.resourceURL?.appendingPathComponent("Resources/Props") else { return nil }
        return NSImage(contentsOf: root.appendingPathComponent("\(name).png"))
    }
    static func cgImage(_ name: String) -> CGImage? {
        image(name)?.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
}
