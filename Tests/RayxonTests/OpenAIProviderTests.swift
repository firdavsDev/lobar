import Testing
import Foundation
@testable import Rayxon

struct OpenAIProviderTests {
    let history = [ChatMessage(role: .user, text: "Salom"), ChatMessage(role: .assistant, text: "Salom!"), ChatMessage(role: .user, text: "Qalaysan?")]

    @Test func requestShapeWithSystemAndBearer() throws {
        let req = try OpenAIProvider.makeRequest(apiKey: "KEY", model: "gpt-x", baseURL: "https://api.openai.com/v1", system: "SYS", history: history)
        #expect(req.url?.absoluteString == "https://api.openai.com/v1/chat/completions")
        #expect(req.value(forHTTPHeaderField: "Authorization") == "Bearer KEY")
        let json = try JSONSerialization.jsonObject(with: req.httpBody!) as! [String: Any]
        let msgs = json["messages"] as! [[String: String]]
        #expect(msgs.map { $0["role"]! } == ["system", "user", "assistant", "user"])
        #expect(msgs[0]["content"] == "SYS")
        #expect(json["model"] as? String == "gpt-x")
        #expect((json["max_completion_tokens"] as? Int ?? 0) >= 1000)
        #expect(json["max_tokens"] == nil)
    }

    @Test func httpErrorShowsOnlyMessage() {
        let body = #"{"error":{"message":"Unsupported parameter: 'max_tokens'","type":"invalid_request_error"}}"#
        let msg = LLMError.http(status: 400, body: body).userMessage
        #expect(msg.contains("Unsupported parameter"))
        #expect(!msg.contains("{"))
    }

    @Test func detectsUnsupportedParameterToDrop() {
        #expect(OpenAIProvider.unsupportedParameter(status: 400, body: #"{"error":{"message":"Unsupported parameter: 'max_tokens' is not supported with this model."}}"#) == "max_tokens")
        #expect(OpenAIProvider.unsupportedParameter(status: 400, body: #"{"error":{"message":"Unsupported value: 'temperature' does not support 0.9 with this model."}}"#) == "temperature")
        #expect(OpenAIProvider.unsupportedParameter(status: 401, body: "bad key") == nil)
    }

    @Test func omittedParametersAreNotSent() throws {
        let req = try OpenAIProvider.makeRequest(apiKey: "K", model: "m", baseURL: "https://api.openai.com/v1", system: "s", history: history, omit: ["temperature", "reasoning_effort"])
        let json = try JSONSerialization.jsonObject(with: req.httpBody!) as! [String: Any]
        #expect(json["temperature"] == nil && json["reasoning_effort"] == nil)
        #expect((json["max_completion_tokens"] as? Int ?? 0) >= 1000)
    }

    @Test func parsesArrayContentAndEmptyLength() throws {
        let arr = #"{"choices":[{"message":{"role":"assistant","content":[{"type":"text","text":"Salom "},{"type":"text","text":"do'st"}]},"finish_reason":"stop"}]}"#.data(using: .utf8)!
        #expect(try OpenAIProvider.parse(arr) == "Salom do'st")
        let empty = #"{"choices":[{"message":{"role":"assistant","content":""},"finish_reason":"length"}]}"#.data(using: .utf8)!
        #expect(throws: LLMError.self) { try OpenAIProvider.parse(empty) }
    }

    @Test func customBaseURLTrailingSlashHandled() throws {
        let req = try OpenAIProvider.makeRequest(apiKey: "K", model: "m", baseURL: "http://localhost:11434/v1/", system: "s", history: history)
        #expect(req.url?.absoluteString == "http://localhost:11434/v1/chat/completions")
    }

    @Test func parsesContent() throws {
        let data = #"{"choices":[{"message":{"role":"assistant","content":"Yaxshi!"},"finish_reason":"stop"}]}"#.data(using: .utf8)!
        #expect(try OpenAIProvider.parse(data) == "Yaxshi!")
    }

    @Test func modelSuggestionsExistForEveryProvider() {
        for kind in LLMProviderKind.allCases {
            #expect(!kind.suggestedModels.isEmpty)
            #expect(kind.suggestedModels.contains(kind.defaultModel))
        }
    }
}

struct ModelCatalogTests {
    @Test func parsesOpenAIStyleList() throws {
        let data = #"{"data":[{"id":"gpt-5.6-terra"},{"id":"whisper-1"},{"id":"gpt-5.6-luna"}]}"#.data(using: .utf8)!
        #expect(try ModelCatalog.parse(.openai, data) == ["gpt-5.6-luna", "gpt-5.6-terra"])
    }
    @Test func parsesGeminiList() throws {
        let data = #"{"models":[{"name":"models/gemini-3.8-flash","supportedGenerationMethods":["generateContent"]},{"name":"models/embedding-001","supportedGenerationMethods":["embedContent"]}]}"#.data(using: .utf8)!
        #expect(try ModelCatalog.parse(.gemini, data) == ["gemini-3.8-flash"])
    }
    @Test func parsesClaudeList() throws {
        let data = #"{"data":[{"id":"claude-haiku-5-5","type":"model"},{"id":"claude-opus-5-5","type":"model"}]}"#.data(using: .utf8)!
        #expect(try ModelCatalog.parse(.claude, data) == ["claude-haiku-5-5", "claude-opus-5-5"])
    }
}
