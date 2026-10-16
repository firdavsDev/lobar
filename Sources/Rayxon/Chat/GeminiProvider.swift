import Foundation

struct GeminiProvider: LLMProvider {
    static let defaultModel = "gemini-3.8-flash"
    var apiKey: String
    var model: String

    static func makeRequest(apiKey: String, model: String, system: String, history: [ChatMessage]) throws -> URLRequest {
        var req = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        let contents = history.map { m -> [String: Any] in
            ["role": m.role == .user ? "user" : "model", "parts": [["text": m.text]]]
        }
        let body: [String: Any] = [
            "systemInstruction": ["parts": [["text": system]]],
            "contents": contents,
            "generationConfig": ["temperature": 1.05, "maxOutputTokens": 400],
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return req
    }

    static func parse(_ data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw LLMError.badResponse(String(data: data, encoding: .utf8) ?? "")
        }
        let text = parts.filter { ($0["thought"] as? Bool) != true }.compactMap { $0["text"] as? String }.joined()
        guard !text.isEmpty else { throw LLMError.badResponse("empty") }
        return text
    }

    func reply(system: String, history: [ChatMessage]) async throws -> String {
        guard !apiKey.isEmpty else { throw LLMError.missingKey }
        let req = try Self.makeRequest(apiKey: apiKey, model: model, system: system, history: history)
        return try Self.parse(try await LLMHTTP.send(req))
    }
}
