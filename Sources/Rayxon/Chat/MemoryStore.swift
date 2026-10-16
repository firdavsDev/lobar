import Foundation

/// Durable facts about the user, persisted as a JSON array. FIFO-capped.
@MainActor
final class MemoryStore {
    static let limit = 40
    let fileURL: URL
    private(set) var facts: [String] = []
    /// Bumped on clear(); async writers pass the generation they started with.
    private(set) var generation = 0

    init(fileURL: URL) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let list = try? JSONDecoder().decode([String].self, from: data) {
            facts = list
        }
    }

    func add(_ new: [String], ifGeneration gen: Int? = nil) {
        if let gen, gen != generation { return }
        for raw in new {
            let fact = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !fact.isEmpty else { continue }
            let key = fact.lowercased()
            if facts.contains(where: { $0.lowercased() == key }) { continue }
            facts.append(fact)
        }
        if facts.count > Self.limit { facts.removeFirst(facts.count - Self.limit) }
        save()
    }

    func contains(_ fact: String) -> Bool { facts.contains { $0.lowercased() == fact.lowercased() } }

    func clear() {
        generation += 1
        facts = []
        save()
    }

    private func save() {
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(facts) { try? data.write(to: fileURL, options: .atomic) }
    }
}
