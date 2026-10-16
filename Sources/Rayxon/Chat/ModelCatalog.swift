import Foundation

/// Fetches the live model list from a provider so the settings picker never goes stale.
enum ModelCatalog {
    static func request(_ kind: LLMProviderKind, apiKey: String, baseURL: String) -> URLRequest? {
        switch kind {
        case .gemini:
            var r = URLRequest(url: URL(string: "https://generativelanguage.googleapis.com/v1beta/models?pageSize=200")!)
            r.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key"); return r
        case .claude:
            var r = URLRequest(url: URL(string: "https://api.anthropic.com/v1/models?limit=100")!)
            r.setValue(apiKey, forHTTPHeaderField: "x-api-key")
            r.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version"); return r
        case .openai:
            var base = baseURL; while base.hasSuffix("/") { base.removeLast() }
            guard let u = URL(string: base + "/models") else { return nil }
            var r = URLRequest(url: u)
            r.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization"); return r
        }
    }

    static func parse(_ kind: LLMProviderKind, _ data: Data) throws -> [String] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw LLMError.badResponse("models") }
        switch kind {
        case .gemini:
            let models = json["models"] as? [[String: Any]] ?? []
            return models.compactMap { m -> String? in
                guard let name = m["name"] as? String,
                      (m["supportedGenerationMethods"] as? [String])?.contains("generateContent") == true else { return nil }
                return name.replacingOccurrences(of: "models/", with: "")
            }.sorted()
        case .claude:
            return (json["data"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String }.sorted()
        case .openai:
            return (json["data"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? String }
                .filter { $0.hasPrefix("gpt") || $0.hasPrefix("o") || $0.contains("llama") || $0.contains("mistral") || $0.contains("qwen") }
                .sorted()
        }
    }

    static func fetch(_ kind: LLMProviderKind, apiKey: String, baseURL: String) async throws -> [String] {
        guard let req = request(kind, apiKey: apiKey, baseURL: baseURL) else { throw LLMError.badResponse("url") }
        return try parse(kind, try await LLMHTTP.send(req))
    }
}
