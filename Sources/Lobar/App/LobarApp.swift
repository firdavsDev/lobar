import AppKit

@main
struct LobarApp {
    static func main() {
        LegacyMigration.run()
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
