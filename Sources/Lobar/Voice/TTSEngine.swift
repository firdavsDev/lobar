import Foundation

enum TTSError: Error, Sendable {
    case toolMissing
    case failed(String)
    case authFailure
}

protocol TTSEngine: Sendable {
    /// Synthesizes `text` to an audio file and returns its URL.
    func synthesize(text: String, voice: String) async throws -> URL
}
