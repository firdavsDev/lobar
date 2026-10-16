import Foundation

/// OpenAI Chat Completions — also works with OpenAI-compatible servers (Ollama, Groq, OpenRouter) via baseURL.
/// Parameters the target model rejects ("Unsupported parameter: 'x'") are dropped automatically and the call retried.
struct OpenAIProvider: LLMProvider {
    static let defaultModel = "gpt-5.6-terra"
    static let defaultBaseURL = "https://api.openai.com/v1"
    var apiKey: String
    var model: String
    var baseURL: String

    static func makeRequest(apiKey: String, model: String, baseURL: String, system: String, history: [ChatMessage],
                            omit: Set<String> = []) throws -> URLRequest {
        var base = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        while base.hasSuffix("/") { base.removeLast() }
        guard let url = URL(string: base + "/chat/completions") else { throw LLMError.badResponse("bad base URL") }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        var messages: [[String: String]] = [["role": "system", "content": system]]
        messages += history.map { ["role": $0.role == .user ? "user" : "assistant", "content": $0.text] }
        var body: [String: Any] = ["model": model, "messages": messages]
        // reasoning models count thinking tokens against this budget, so leave room
        if !omit.contains("max_completion_tokens") { body["max_completion_tokens"] = 1500 }
        if !omit.contains("temperature") { body["temperature"] = 0.9 }
        if !omit.contains("reasoning_effort") { body["reasoning_effort"] = "low" }
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return req
    }

    static func parse(_ data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let choice = choices.first,
              let message = choice["message"] as? [String: Any] else {
            throw LLMError.badResponse(String(data: data, encoding: .utf8) ?? "")
        }
        var text = ""
        if let s = message["content"] as? String { text = s }
        else if let parts = message["content"] as? [[String: Any]] {
            text = parts.compactMap { ($0["type"] as? String) == "text" ? $0["text"] as? String : nil }.joined()
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            if choice["finish_reason"] as? String == "length" { throw LLMError.badResponse("model o'ylab bo'lmadi (token limiti). Boshqa model tanlang.") }
            throw LLMError.badResponse("bo'sh javob")
        }
        return trimmed
    }

    /// Name of the parameter the server rejected, if the error is of that shape.
    static func unsupportedParameter(status: Int, body: String) -> String? {
        guard status == 400 else { return nil }
        let msg = LLMError.extractMessage(body).lowercased()
        guard msg.contains("unsupported") || msg.contains("not supported") || msg.contains("unrecognized") else { return nil }
        guard let r = msg.range(of: #"'([a-z_]+)'"#, options: .regularExpression) else { return nil }
        return String(msg[r]).replacingOccurrences(of: "'", with: "")
    }

    func reply(system: String, history: [ChatMessage]) async throws -> String {
        guard !apiKey.isEmpty || !baseURL.contains("openai.com") else { throw LLMError.missingKey }
        var omit: Set<String> = []
        for _ in 0..<4 {
            let req = try Self.makeRequest(apiKey: apiKey, model: model, baseURL: baseURL, system: system, history: history, omit: omit)
            do {
                return try Self.parse(try await LLMHTTP.send(req))
            } catch LLMError.http(let status, let body) {
                guard let param = Self.unsupportedParameter(status: status, body: body), !omit.contains(param) else {
                    throw LLMError.http(status: status, body: body)
                }
                omit.insert(param)
            }
        }
        throw LLMError.badResponse("too many parameter retries")
    }
}
