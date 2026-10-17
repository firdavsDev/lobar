import Testing
import Foundation
@testable import Lobar

@MainActor
struct TaskStoreTests {
    func temp() -> TaskStore {
        TaskStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("lobar-tasks-\(UUID().uuidString).json"))
    }

    @Test func addsTogglesAndPersists() {
        let store = temp()
        let id = store.add("Suv ichish")
        store.add("Kod yozish")
        store.toggle(id)
        #expect(store.tasks.map(\.title) == ["Suv ichish", "Kod yozish"])
        #expect(store.tasks[0].done == true)
        let reloaded = TaskStore(fileURL: store.fileURL)
        #expect(reloaded.tasks.map(\.done) == [true, false])
    }

    @Test func removesAndClearsDone() {
        let store = temp()
        let a = store.add("a"); let b = store.add("b"); _ = store.add("c")
        store.toggle(a); store.toggle(b)
        store.remove(b)
        #expect(store.tasks.map(\.title) == ["a", "c"])
        store.clearDone()
        #expect(store.tasks.map(\.title) == ["c"])
    }

    @Test func ignoresBlankTitles() {
        let store = temp()
        _ = store.add("   ")
        #expect(store.tasks.isEmpty)
    }
}
