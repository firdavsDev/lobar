import Foundation
import Observation

/// UserDefaults-backed settings. API keys live in Keychain (see KeychainStore).
@MainActor
@Observable
final class SettingsStore {
    private let d = UserDefaults.standard

    var provider: LLMProviderKind { didSet { d.set(provider.rawValue, forKey: "provider") } }
    var geminiModel: String { didSet { d.set(geminiModel, forKey: "geminiModel") } }
    var claudeModel: String { didSet { d.set(claudeModel, forKey: "claudeModel") } }
    var openaiModel: String { didSet { d.set(openaiModel, forKey: "openaiModel") } }
    var openaiBaseURL: String { didSet { d.set(openaiBaseURL, forKey: "openaiBaseURL") } }
    var userName: String { didSet { d.set(userName, forKey: "userName") } }
    var outfit: String { didSet { d.set(outfit, forKey: "outfit") } }
    var petName: String { didSet { d.set(petName, forKey: "petName") } }
    var relationship: Relationship { didSet { d.set(relationship.rawValue, forKey: "relationship") } }
    var petScale: Double { didSet { d.set(petScale, forKey: "petScale") } }
    var bubbleWidth: Double { didSet { d.set(bubbleWidth, forKey: "bubbleWidth") } }
    var bubbleFontSize: Double { didSet { d.set(bubbleFontSize, forKey: "bubbleFontSize") } }

    var voiceEnabled: Bool { didSet { d.set(voiceEnabled, forKey: "voiceEnabled") } }
    var sfxEnabled: Bool { didSet { d.set(sfxEnabled, forKey: "sfxEnabled") } }
    var llmChatter: Bool { didSet { d.set(llmChatter, forKey: "llmChatter") } }
    var nightMode: Bool { didSet { d.set(nightMode, forKey: "nightMode") } }
    var weatherEnabled: Bool { didSet { d.set(weatherEnabled, forKey: "weatherEnabled") } }
    var weatherOutfit: Bool { didSet { d.set(weatherOutfit, forKey: "weatherOutfit") } }
    var appReactions: Bool { didSet { d.set(appReactions, forKey: "appReactions") } }
    var projectsFolder: String { didSet { d.set(projectsFolder, forKey: "projectsFolder") } }
    var funEvents: Bool { didSet { d.set(funEvents, forKey: "funEvents") } }
    var lanPeers: Bool { didSet { d.set(lanPeers, forKey: "lanPeers") } }
    var voiceName: String { didSet { d.set(voiceName, forKey: "voiceName") } }
    var volume: Double { didSet { d.set(volume, forKey: "volume") } }

    var waterEnabled: Bool { didSet { d.set(waterEnabled, forKey: "waterEnabled") } }
    var waterMinutes: Int { didSet { d.set(waterMinutes, forKey: "waterMinutes") } }
    var eyesEnabled: Bool { didSet { d.set(eyesEnabled, forKey: "eyesEnabled") } }
    var eyesMinutes: Int { didSet { d.set(eyesMinutes, forKey: "eyesMinutes") } }
    var postureEnabled: Bool { didSet { d.set(postureEnabled, forKey: "postureEnabled") } }
    var postureMinutes: Int { didSet { d.set(postureMinutes, forKey: "postureMinutes") } }
    var pomodoroWork: Int { didSet { d.set(pomodoroWork, forKey: "pomodoroWork") } }
    var pomodoroBreak: Int { didSet { d.set(pomodoroBreak, forKey: "pomodoroBreak") } }

    var affection: Double { didSet { d.set(affection, forKey: "affection") } }
    var lastInteraction: Date { didSet { d.set(lastInteraction, forKey: "lastInteraction") } }
    var chatterEnabled: Bool { didSet { d.set(chatterEnabled, forKey: "chatterEnabled") } }

    var geminiKey: String { didSet { Self.store(geminiKey, "gemini") } }
    var claudeKey: String { didSet { Self.store(claudeKey, "anthropic") } }
    var openaiKey: String { didSet { Self.store(openaiKey, "openai") } }

    private static func store(_ value: String, _ account: String) {
        if !KeychainStore.set(value, account: account) { Log.app.error("Keychain write failed for \(account)") }
    }

    init() {
        provider = LLMProviderKind(rawValue: d.string(forKey: "provider") ?? "") ?? .gemini
        geminiModel = d.string(forKey: "geminiModel") ?? GeminiProvider.defaultModel
        claudeModel = d.string(forKey: "claudeModel") ?? ClaudeProvider.defaultModel
        openaiModel = d.string(forKey: "openaiModel") ?? OpenAIProvider.defaultModel
        openaiBaseURL = d.string(forKey: "openaiBaseURL") ?? OpenAIProvider.defaultBaseURL
        userName = d.string(forKey: "userName") ?? ""
        outfit = d.string(forKey: "outfit") ?? "atlas"
        petName = d.string(forKey: "petName") ?? "Rayxon"
        relationship = Relationship(rawValue: d.string(forKey: "relationship") ?? "") ?? .friend
        petScale = d.object(forKey: "petScale") as? Double ?? 1.0
        bubbleWidth = d.object(forKey: "bubbleWidth") as? Double ?? 240
        bubbleFontSize = d.object(forKey: "bubbleFontSize") as? Double ?? 13
        voiceEnabled = d.object(forKey: "voiceEnabled") as? Bool ?? true
        sfxEnabled = d.object(forKey: "sfxEnabled") as? Bool ?? true
        llmChatter = d.object(forKey: "llmChatter") as? Bool ?? true
        nightMode = d.object(forKey: "nightMode") as? Bool ?? true
        weatherEnabled = d.object(forKey: "weatherEnabled") as? Bool ?? true
        weatherOutfit = d.object(forKey: "weatherOutfit") as? Bool ?? false
        appReactions = d.object(forKey: "appReactions") as? Bool ?? true
        projectsFolder = d.string(forKey: "projectsFolder") ?? ""
        funEvents = d.object(forKey: "funEvents") as? Bool ?? true
        lanPeers = d.object(forKey: "lanPeers") as? Bool ?? true
        voiceName = d.string(forKey: "voiceName") ?? "uz-UZ-MadinaNeural"
        volume = d.object(forKey: "volume") as? Double ?? 0.8
        waterEnabled = d.object(forKey: "waterEnabled") as? Bool ?? true
        waterMinutes = d.object(forKey: "waterMinutes") as? Int ?? 45
        eyesEnabled = d.object(forKey: "eyesEnabled") as? Bool ?? true
        eyesMinutes = d.object(forKey: "eyesMinutes") as? Int ?? 20
        postureEnabled = d.object(forKey: "postureEnabled") as? Bool ?? true
        postureMinutes = d.object(forKey: "postureMinutes") as? Int ?? 60
        pomodoroWork = d.object(forKey: "pomodoroWork") as? Int ?? 30
        pomodoroBreak = d.object(forKey: "pomodoroBreak") as? Int ?? 10
        affection = d.object(forKey: "affection") as? Double ?? 55
        lastInteraction = d.object(forKey: "lastInteraction") as? Date ?? Date()
        chatterEnabled = d.object(forKey: "chatterEnabled") as? Bool ?? true
        geminiKey = KeychainStore.get("gemini") ?? ""
        claudeKey = KeychainStore.get("anthropic") ?? ""
        openaiKey = KeychainStore.get("openai") ?? ""
    }

    var displayName: String { petName.trimmingCharacters(in: .whitespaces).isEmpty ? "Rayxon" : petName }

    func key(for kind: LLMProviderKind) -> String {
        switch kind { case .gemini: return geminiKey; case .claude: return claudeKey; case .openai: return openaiKey }
    }
    func model(for kind: LLMProviderKind) -> String {
        switch kind { case .gemini: return geminiModel; case .claude: return claudeModel; case .openai: return openaiModel }
    }
    func setModel(_ m: String, for kind: LLMProviderKind) {
        switch kind { case .gemini: geminiModel = m; case .claude: claudeModel = m; case .openai: openaiModel = m }
    }

    func makeProvider() -> LLMProvider? {
        switch provider {
        case .gemini: return geminiKey.isEmpty ? nil : GeminiProvider(apiKey: geminiKey, model: geminiModel)
        case .claude: return claudeKey.isEmpty ? nil : ClaudeProvider(apiKey: claudeKey, model: claudeModel)
        case .openai:
            let local = !openaiBaseURL.contains("openai.com")
            return (openaiKey.isEmpty && !local) ? nil : OpenAIProvider(apiKey: openaiKey, model: openaiModel, baseURL: openaiBaseURL)
        }
    }
}
