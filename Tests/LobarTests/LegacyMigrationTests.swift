import Testing
import Foundation
@testable import Lobar

struct LegacyMigrationTests {
    func suite() -> (name: String, defaults: UserDefaults) {
        let name = "lobar-test-\(UUID().uuidString)"
        return (name, UserDefaults(suiteName: name)!)
    }

    @Test func copiesOldDefaultsOnceWithoutOverwriting() {
        let old = suite(), new = suite()
        defer { UserDefaults.standard.removePersistentDomain(forName: old.name); UserDefaults.standard.removePersistentDomain(forName: new.name) }
        old.defaults.set("Lobar", forKey: "petName")
        old.defaults.set(1.4, forKey: "petScale")
        new.defaults.set("adras", forKey: "outfit")
        old.defaults.set("atlas", forKey: "outfit")

        LegacyMigration.migrateDefaults(fromDomain: old.name, into: new.defaults)
        #expect(new.defaults.string(forKey: "petName") == "Lobar")
        #expect(new.defaults.double(forKey: "petScale") == 1.4)
        #expect(new.defaults.string(forKey: "outfit") == "adras")

        old.defaults.set("Rayxon", forKey: "petName")
        new.defaults.removeObject(forKey: "petName")
        LegacyMigration.migrateDefaults(fromDomain: old.name, into: new.defaults)
        #expect(new.defaults.string(forKey: "petName") == nil)
    }

    @Test func movesOldFolderOnlyWhenNewIsMissing() throws {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("lobar-mig-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: root) }
        let old = root.appendingPathComponent("Rayxon"), new = root.appendingPathComponent("Lobar")
        try fm.createDirectory(at: old, withIntermediateDirectories: true)
        try Data("[]".utf8).write(to: old.appendingPathComponent("memory.json"))

        LegacyMigration.migrateFolder(from: old, to: new)
        #expect(fm.fileExists(atPath: new.appendingPathComponent("memory.json").path))
        #expect(!fm.fileExists(atPath: old.path))

        try fm.createDirectory(at: old, withIntermediateDirectories: true)
        try Data("old".utf8).write(to: old.appendingPathComponent("memory.json"))
        LegacyMigration.migrateFolder(from: old, to: new)
        #expect(try Data(contentsOf: new.appendingPathComponent("memory.json")) == Data("[]".utf8))
    }
}
