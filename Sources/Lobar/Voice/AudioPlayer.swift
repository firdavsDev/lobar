import AVFoundation

/// Serial MP3 playback with start/finish callbacks (drives the talking animation).
@MainActor
final class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var queue: [URL] = []
    private var generation = 0
    var volume: Float = 0.8
    var onStart: (() -> Void)?
    var onFinish: (() -> Void)?

    func enqueue(_ url: URL) {
        queue.append(url)
        if player == nil { playNext() }
    }

    func stopAll() {
        generation += 1
        queue.forEach { try? FileManager.default.removeItem(at: $0) }
        queue.removeAll()
        if let url = player?.url { try? FileManager.default.removeItem(at: url) }
        player?.stop()
        player = nil
        onFinish?()
    }

    private func playNext() {
        guard !queue.isEmpty else { player = nil; onFinish?(); return }
        let url = queue.removeFirst()
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.volume = volume
            player = p
            p.play()
            Log.voice.info("playing \(url.lastPathComponent) (\(p.duration, format: .fixed(precision: 1))s)")
            onStart?()
        } catch {
            Log.voice.error("play failed: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: url)
            playNext()
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let url = player.url
        let id = ObjectIdentifier(player)
        Task { @MainActor in
            if let url { try? FileManager.default.removeItem(at: url) }
            guard let current = self.player, ObjectIdentifier(current) == id else { return }   // stale callback after stopAll()
            self.playNext()
        }
    }
}
