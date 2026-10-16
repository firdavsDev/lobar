import Foundation

struct ChatHistory: Sendable {
    var limit: Int
    private(set) var messages: [ChatMessage] = []
    init(limit: Int = 16) { self.limit = limit }
    mutating func append(_ m: ChatMessage) {
        messages.append(m)
        if messages.count > limit { messages.removeFirst(messages.count - limit) }
    }
    mutating func clear() { messages.removeAll() }
}

/// Orchestrates a chat turn: persona + memory → provider → fact extraction.
@MainActor
final class ChatSession {
    var providerFactory: () -> LLMProvider?
    let memory: MemoryStore
    var userName: () -> String?
    var petName: () -> String = { Persona.name }
    var tone: () -> Mood.Tone = { .sassy }
    var relationship: () -> Relationship = { .friend }
    var history = ChatHistory()
    private var turnsSinceExtraction = 0

    init(memory: MemoryStore, providerFactory: @escaping () -> LLMProvider?, userName: @escaping () -> String?) {
        self.memory = memory
        self.providerFactory = providerFactory
        self.userName = userName
    }

    func send(_ text: String) async throws -> String {
        guard let provider = providerFactory() else { throw LLMError.missingKey }
        let system = Persona.systemPrompt(facts: memory.facts, now: Date(), userName: userName(), name: petName(), tone: tone(), relationship: relationship())
        var pending = history
        pending.append(ChatMessage(role: .user, text: text))
        let reply = try await provider.reply(system: system, history: pending.messages)
        history.append(ChatMessage(role: .user, text: text))
        history.append(ChatMessage(role: .assistant, text: reply))
        turnsSinceExtraction += 1
        if turnsSinceExtraction >= 3 || text.count > 40 {
            turnsSinceExtraction = 0
            Task { await extractFacts(from: text, provider: provider) }
        }
        return reply
    }

    /// One short unprompted line generated from live context; appended to history as hers.
    func unprompted(context: String) async throws -> String {
        guard let provider = providerFactory() else { throw LLMError.missingKey }
        let system = Persona.systemPrompt(facts: memory.facts, now: Date(), userName: userName(), name: petName(), tone: tone(), relationship: relationship())
        var msgs = history.messages
        msgs.append(ChatMessage(role: .user, text: "[tizim xabari, foydalanuvchi ko'rmaydi] \(context) Shu holatdan kelib chiqib o'zing gap boshla: 1 jumla, 18 so'zdan oshmasin, savol yoki piching bo'lsin, salomlashma. Faqat gapning o'zini yoz."))
        let reply = try await provider.reply(system: system, history: msgs)
        let clean = reply.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "")
        history.append(ChatMessage(role: .assistant, text: clean))
        return clean
    }

    private func extractFacts(from text: String, provider: LLMProvider) async {
        let generation = memory.generation
        let prompt = Persona.extractionPrompt(userText: text, existing: memory.facts)
        guard let raw = try? await provider.reply(system: "Sen faktlarni JSON massiv sifatida ajratuvchi yordamchisan.",
                                                  history: [ChatMessage(role: .user, text: prompt)]) else { return }
        let facts = Persona.parseFacts(raw)
        if !facts.isEmpty { memory.add(facts, ifGeneration: generation) }
    }
}
