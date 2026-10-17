import Foundation

struct ChatMessage: Equatable, Sendable, Codable {
    enum Role: String, Codable, Sendable { case user, assistant }
    var role: Role
    var text: String
}

enum LLMError: Error, Equatable, Sendable {
    case missingKey
    case http(status: Int, body: String)
    case badResponse(String)
    case refusal

    var userMessage: String {
        switch self {
        case .missingKey: return "API kalit yo'q. Sozlamalarga kiring."
        case .http(let status, let body):
            if status == 429 { return "Hozir band ekanman (429). Birozdan keyin so'rang." }
            if status == 401 || status == 403 { return "Kalit noto'g'ri yoki ruxsat yo'q (\(status)). Sozlamalarni tekshiring." }
            return "API xato \(status): \(LLMError.extractMessage(body).prefix(200))"
        case .badResponse(let s): return "Javobni tushunmadim: \(s.prefix(120))"
        case .refusal: return "Bunga javob bermayman."
        }
    }
}

extension LLMError {
    /// Pulls `error.message` (OpenAI/Gemini/Claude shapes) out of a JSON error body; falls back to the raw text.
    static func extractMessage(_ body: String) -> String {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return body.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let err = json["error"] as? [String: Any] {
            if let m = err["message"] as? String { return m }
            if let m = err["msg"] as? String { return m }
        }
        if let m = json["message"] as? String { return m }
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

protocol LLMProvider: Sendable {
    func reply(system: String, history: [ChatMessage]) async throws -> String
}

enum LLMProviderKind: String, CaseIterable, Codable, Sendable {
    case gemini, claude, openai
    var title: String {
        switch self { case .gemini: return "Gemini"; case .claude: return "Claude"; case .openai: return "OpenAI" }
    }
    var defaultModel: String {
        switch self {
        case .gemini: return GeminiProvider.defaultModel
        case .claude: return ClaudeProvider.defaultModel
        case .openai: return OpenAIProvider.defaultModel
        }
    }
    var suggestedModels: [String] {
        switch self {
        case .gemini: return ["gemini-3.8-flash", "gemini-3.5-flash-lite", "gemini-3.1-pro"]
        case .claude: return ClaudeProvider.models
        case .openai: return ["gpt-5.6-terra", "gpt-5.6-luna", "gpt-5.6-sol", "gpt-6-astra"]
        }
    }
    var keyURL: String {
        switch self {
        case .gemini: return "https://aistudio.google.com/apikey"
        case .claude: return "https://platform.claude.com/"
        case .openai: return "https://platform.openai.com/api-keys"
        }
    }
}

/// Shared URLSession helper with a 30s timeout and HTTP error surfacing.
enum LLMHTTP {
    static let session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 30
        return URLSession(configuration: cfg)
    }()

    static func send(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw LLMError.badResponse("no http response") }
        guard (200..<300).contains(http.statusCode) else {
            throw LLMError.http(status: http.statusCode, body: String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }
}
