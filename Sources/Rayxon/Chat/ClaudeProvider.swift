import Foundation

struct ClaudeProvider: LLMProvider {
    static let defaultModel = "claude-haiku-5-5"
    static let models = ["claude-haiku-5-5", "claude-sonnet-5-5", "claude-opus-5-5"]
    var apiKey: String
    var model: String

    static func makeRequest(apiKey: String, model: String, system: String, history: [ChatMessage]) throws -> URLRequest {
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        // Claude requires strictly alternating roles starting with user: merge consecutive same-role turns.
        var messages: [[String: String]] = []
        for m in history {
            let role = m.role == .user ? "user" : "assistant"
            if let last = messages.last, last["role"] == role {
                messages[messages.count - 1]["content"] = (last["content"] ?? "") + "\n" + m.text
            } else {
                messages.append(["role": role, "content": m.text])
            }
        }
        if messages.first?["role"] == "assistant" { messages.removeFirst() }
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 400,
            "system": system,
            "messages": messages,
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return req
    }

    static func parse(_ data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            throw LLMError.badResponse(String(data: data, encoding: .utf8) ?? "")
        }
        if json["stop_reason"] as? String == "refusal" { throw LLMError.refusal }
        let text = content.filter { $0["type"] as? String == "text" }.compactMap { $0["text"] as? String }.joined()
        guard !text.isEmpty else { throw LLMError.badResponse("empty") }
        return text
    }

    func reply(system: String, history: [ChatMessage]) async throws -> String {
        guard !apiKey.isEmpty else { throw LLMError.missingKey }
        let req = try Self.makeRequest(apiKey: apiKey, model: model, system: system, history: history)
        return try Self.parse(try await LLMHTTP.send(req))
    }
}
