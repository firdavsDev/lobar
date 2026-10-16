import Testing
import Foundation
@testable import Rayxon

struct ProviderTests {
    let history = [ChatMessage(role: .user, text: "Salom"), ChatMessage(role: .assistant, text: "Salom!"), ChatMessage(role: .user, text: "Qalaysan?")]

    @Test func geminiRequestShape() throws {
        let req = try GeminiProvider.makeRequest(apiKey: "KEY", model: "gemini-x", system: "SYS", history: history)
        #expect(req.url?.absoluteString == "https://generativelanguage.googleapis.com/v1beta/models/gemini-x:generateContent")
        #expect(req.value(forHTTPHeaderField: "x-goog-api-key") == "KEY")
        let json = try JSONSerialization.jsonObject(with: req.httpBody!) as! [String: Any]
        let sys = json["systemInstruction"] as! [String: Any]
        #expect(((sys["parts"] as! [[String: Any]])[0]["text"] as! String) == "SYS")
        let contents = json["contents"] as! [[String: Any]]
        #expect(contents.map { $0["role"] as! String } == ["user", "model", "user"])
    }

    @Test func geminiParsesText() throws {
        let data = #"{"candidates":[{"content":{"parts":[{"text":"Yaxshi, "},{"text":"rahmat."}],"role":"model"}}]}"#.data(using: .utf8)!
        #expect(try GeminiProvider.parse(data) == "Yaxshi, rahmat.")
    }

    @Test func claudeRequestShape() throws {
        let req = try ClaudeProvider.makeRequest(apiKey: "KEY", model: "claude-haiku-5-5", system: "SYS", history: history)
        #expect(req.url?.absoluteString == "https://api.anthropic.com/v1/messages")
        #expect(req.value(forHTTPHeaderField: "x-api-key") == "KEY")
        #expect(req.value(forHTTPHeaderField: "anthropic-version") == "2023-06-01")
        let json = try JSONSerialization.jsonObject(with: req.httpBody!) as! [String: Any]
        #expect(json["system"] as? String == "SYS")
        #expect((json["max_tokens"] as? Int ?? 0) > 0)
        let messages = json["messages"] as! [[String: Any]]
        #expect(messages.map { $0["role"] as! String } == ["user", "assistant", "user"])
    }

    @Test func claudeParsesTextAndRefusal() throws {
        let ok = #"{"content":[{"type":"text","text":"Salom!"}],"stop_reason":"end_turn"}"#.data(using: .utf8)!
        #expect(try ClaudeProvider.parse(ok) == "Salom!")
        let refusal = #"{"content":[],"stop_reason":"refusal"}"#.data(using: .utf8)!
        #expect(throws: LLMError.self) { try ClaudeProvider.parse(refusal) }
    }

    @Test func httpErrorBodyIsSurfaced() {
        let err = LLMError.http(status: 429, body: "quota")
        #expect(err.userMessage.contains("429"))
    }
}

@MainActor
struct MemoryStoreTests {
    func tempStore() -> MemoryStore {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("rayxon-mem-\(UUID().uuidString).json")
        return MemoryStore(fileURL: url)
    }

    @Test func addsDedupesAndPersists() throws {
        let store = tempStore()
        store.add(["Ismi Davron", "ismi davron ", "Kofe yoqtiradi"])
        #expect(store.facts == ["Ismi Davron", "Kofe yoqtiradi"])
        let reloaded = MemoryStore(fileURL: store.fileURL)
        #expect(reloaded.facts == ["Ismi Davron", "Kofe yoqtiradi"])
    }

    @Test func capsAtLimitFIFO() {
        let store = tempStore()
        store.add((0..<45).map { "fakt \($0)" })
        #expect(store.facts.count == MemoryStore.limit)
        #expect(store.facts.first == "fakt 5")
    }

    @Test func clearRemovesAll() {
        let store = tempStore()
        store.add(["a"]); store.clear()
        #expect(store.facts.isEmpty)
        #expect(MemoryStore(fileURL: store.fileURL).facts.isEmpty)
    }
}

struct PersonaTests {
    @Test func systemPromptIncludesNameMemoryAndTime() {
        let prompt = Persona.systemPrompt(facts: ["Ismi Davron"], now: Date(timeIntervalSince1970: 0), userName: nil)
        #expect(prompt.contains("Rayxon"))
        #expect(prompt.contains("Ismi Davron"))
        #expect(prompt.contains("lotin"))
    }

    @Test func extractionPromptAsksForJSONArray() {
        let p = Persona.extractionPrompt(userText: "Men Toshkentda yashayman", existing: [])
        #expect(p.contains("JSON"))
        #expect(p.contains("Toshkentda"))
    }

    @Test func parsesFactArrayLeniently() {
        #expect(Persona.parseFacts("```json\n[\"a\", \"b\"]\n```") == ["a", "b"])
        #expect(Persona.parseFacts("[]") == [])
        #expect(Persona.parseFacts("nothing") == [])
    }
}

struct ChatSessionTests {
    @Test func historyIsTrimmedToLimit() {
        var h = ChatHistory(limit: 4)
        for i in 0..<10 { h.append(ChatMessage(role: i % 2 == 0 ? .user : .assistant, text: "\(i)")) }
        #expect(h.messages.count == 4)
        #expect(h.messages.first?.text == "6")
    }
}
