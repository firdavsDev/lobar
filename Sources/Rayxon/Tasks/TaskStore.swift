import Foundation

struct TaskItem: Codable, Equatable, Identifiable, Sendable {
    var id: UUID = UUID()
    var title: String
    var done: Bool = false
    var createdAt: Date = Date()
    var dueAt: Date? = nil
    var notified: Bool = false
}

/// Simple JSON-backed todo list.
@MainActor
@Observable
final class TaskStore {
    let fileURL: URL
    private(set) var tasks: [TaskItem] = []
    var onCompleted: ((TaskItem) -> Void)?

    init(fileURL: URL) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let list = try? { let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return try d.decode([TaskItem].self, from: data) }() {
            tasks = list
        }
    }

    @discardableResult
    func add(_ title: String, dueAt: Date? = nil) -> UUID {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return UUID() }
        let item = TaskItem(title: t, dueAt: dueAt)
        tasks.append(item)
        save()
        return item.id
    }

    func toggle(_ id: UUID) {
        guard let i = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[i].done.toggle()
        save()
        if tasks[i].done { onCompleted?(tasks[i]) }
    }

    func remove(_ id: UUID) {
        tasks.removeAll { $0.id == id }
        save()
    }

    func clearDone() {
        tasks.removeAll(where: \.done)
        save()
    }

    var openCount: Int { tasks.filter { !$0.done }.count }

    /// Open tasks whose due time has passed and were not announced yet; marks them announced.
    func dueTasks(at now: Date) -> [TaskItem] {
        var out: [TaskItem] = []
        for i in tasks.indices where !tasks[i].done && !tasks[i].notified {
            if let d = tasks[i].dueAt, d <= now { tasks[i].notified = true; out.append(tasks[i]) }
        }
        if !out.isEmpty { save() }
        return out
    }

    private func save() {
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        if let data = try? enc.encode(tasks) { try? data.write(to: fileURL, options: .atomic) }
    }
}
