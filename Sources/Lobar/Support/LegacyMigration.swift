import Foundation

/// One-time carry-over of data saved while the app was called Rayxon (bundle id `dev.davronbek.rayxon`).
/// Runs before any store touches UserDefaults or Application Support. Keychain keys move lazily in `KeychainStore.get`.
enum LegacyMigration {
    static let legacyID = "dev.davronbek.rayxon"
    static let legacyFolder = "Rayxon"
    static let doneKey = "migratedFromRayxon"

    static func run() {
        migrateDefaults(fromDomain: legacyID, into: .standard)
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        migrateFolder(from: base.appendingPathComponent(legacyFolder, isDirectory: true),
                      to: base.appendingPathComponent("Lobar", isDirectory: true))
    }

    /// Copies the old preferences domain into `defaults` once; keys already set there win.
    static func migrateDefaults(fromDomain old: String, into defaults: UserDefaults) {
        guard !defaults.bool(forKey: doneKey) else { return }
        for (key, value) in defaults.persistentDomain(forName: old) ?? [:] where defaults.object(forKey: key) == nil {
            defaults.set(value, forKey: key)
        }
        defaults.set(true, forKey: doneKey)
    }

    /// Moves the old Application Support folder unless the new one already exists.
    static func migrateFolder(from old: URL, to new: URL) {
        let fm = FileManager.default
        guard fm.fileExists(atPath: old.path), !fm.fileExists(atPath: new.path) else { return }
        do { try fm.moveItem(at: old, to: new) } catch { Log.app.error("Legacy folder move failed: \(error.localizedDescription)") }
    }
}
