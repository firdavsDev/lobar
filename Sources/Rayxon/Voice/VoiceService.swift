import Foundation

/// Speaks text through the configured engine, rate-limited and never crashing on failure.
@MainActor
final class VoiceService {
    private let engine: TTSEngine
    private let player = AudioPlayer()
    private var mutedForSession = false
    private var lastRequest = Date.distantPast
    private var warnedMissingTool = false
    var isEnabled: () -> Bool
    var voiceName: () -> String
    var volume: () -> Double
    var onProblem: ((String) -> Void)?
    private var inflight: [Task<Void, Never>] = []

    init(engine: TTSEngine, isEnabled: @escaping () -> Bool, voiceName: @escaping () -> String, volume: @escaping () -> Double) {
        self.engine = engine
        self.isEnabled = isEnabled
        self.voiceName = voiceName
        self.volume = volume
    }

    var onSpeakingStart: (() -> Void)? { get { player.onStart } set { player.onStart = newValue } }
    var onSpeakingEnd: (() -> Void)? { get { player.onFinish } set { player.onFinish = newValue } }

    func speak(_ text: String, force: Bool = false) {
        guard force || isEnabled(), !mutedForSession else { return }
        guard Date().timeIntervalSince(lastRequest) > 0.8 else { return }
        lastRequest = Date()
        let voice = voiceName()
        player.volume = Float(volume())
        let task = Task { [weak self] in
            guard let self else { return }
            do {
                let url = try await engine.synthesize(text: text, voice: voice)
                if Task.isCancelled || (!force && !isEnabled()) { try? FileManager.default.removeItem(at: url); return }
                player.enqueue(url)
            } catch TTSError.toolMissing {
                if !warnedMissingTool {
                    warnedMissingTool = true
                    onProblem?("Ovoz uchun 'uv' kerak: brew install uv")
                }
            } catch TTSError.authFailure {
                mutedForSession = true
                onProblem?("Ovoz hozircha ishlamayapti (Edge TTS 403).")
            } catch {
                if !Task.isCancelled { Log.voice.error("tts failed: \(String(describing: error))") }
            }
        }
        inflight.removeAll { $0.isCancelled }
        inflight.append(task)
    }

    func stop() {
        inflight.forEach { $0.cancel() }
        inflight.removeAll()
        player.stopAll()
    }
}
