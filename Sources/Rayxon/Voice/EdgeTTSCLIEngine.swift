import Foundation

/// Runs the python `edge-tts` CLI through `uv tool run`. Microsoft rotates the DRM token
/// occasionally; on an auth failure we retry once with `edge-tts@latest`.
struct EdgeTTSCLIEngine: TTSEngine {
    static let candidateUVPaths = ["/opt/homebrew/bin/uv", "/usr/local/bin/uv",
                                   NSHomeDirectory() + "/.local/bin/uv", NSHomeDirectory() + "/.cargo/bin/uv"]

    static func findUV() -> String? {
        candidateUVPaths.first { FileManager.default.isExecutableFile(atPath: $0) }
    }

    static func arguments(voice: String, text: String, output: URL, latest: Bool) -> [String] {
        ["tool", "run", "--from", latest ? "edge-tts@latest" : "edge-tts", "edge-tts",
         "--voice", voice, "--text", text, "--write-media", output.path]
    }

    static func looksLikeAuthFailure(_ stderr: String) -> Bool {
        let s = stderr.lowercased()
        return s.contains("invalid response status") || s.contains("handshake")
            || s.range(of: #"\b40[13]\b"#, options: .regularExpression) != nil
    }

    /// Strips markdown-ish noise so it is not read aloud.
    static func sanitize(_ text: String) -> String {
        var s = text.replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "#", with: "")
        s = s.unicodeScalars.filter { !($0.properties.isEmojiPresentation || $0.value >= 0x1F300) }.map(String.init).joined()
        s = s.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func synthesize(text: String, voice: String) async throws -> URL {
        guard let uv = Self.findUV() else { throw TTSError.toolMissing }
        let clean = Self.sanitize(text)
        guard !clean.isEmpty else { throw TTSError.failed("empty") }
        let out = FileManager.default.temporaryDirectory.appendingPathComponent("rayxon-\(UUID().uuidString).mp3")
        do {
            try await Self.run(uv: uv, args: Self.arguments(voice: voice, text: clean, output: out, latest: false))
        } catch TTSError.authFailure {
            try await Self.run(uv: uv, args: Self.arguments(voice: voice, text: clean, output: out, latest: true))
        }
        guard FileManager.default.fileExists(atPath: out.path) else { throw TTSError.failed("no output") }
        return out
    }

    private static func run(uv: String, args: [String], timeout: TimeInterval = 40) async throws {
        let errFile = FileManager.default.temporaryDirectory.appendingPathComponent("rayxon-tts-\(UUID().uuidString).log")
        FileManager.default.createFile(atPath: errFile.path, contents: nil)
        defer { try? FileManager.default.removeItem(at: errFile) }
        let p = Process()
        p.executableURL = URL(fileURLWithPath: uv)
        p.arguments = args
        p.standardError = try FileHandle(forWritingTo: errFile)   // file sink: no pipe-buffer deadlock
        p.standardOutput = FileHandle.nullDevice
        let box = ProcessBox(p)
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                let once = ResumeOnce(cont)
                p.terminationHandler = { proc in
                    let stderr = (try? String(contentsOf: errFile, encoding: .utf8)) ?? ""
                    if proc.terminationStatus == 0 { once.resume(nil) }
                    else if looksLikeAuthFailure(stderr) { once.resume(TTSError.authFailure) }
                    else { once.resume(TTSError.failed(String(stderr.suffix(300)))) }
                }
                do { try p.run() } catch { once.resume(TTSError.failed(error.localizedDescription)); return }
                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                    if box.process.isRunning { box.process.terminate(); once.resume(TTSError.failed("timeout")) }
                }
            }
        } onCancel: {
            if box.process.isRunning { box.process.terminate() }
        }
    }
}

/// Keeps the Process alive until termination and lets the cancellation handler reach it.
private final class ProcessBox: @unchecked Sendable {
    let process: Process
    init(_ p: Process) { process = p }
}

/// Guards a continuation so timeout + termination cannot both resume it.
private final class ResumeOnce: @unchecked Sendable {
    private let lock = NSLock()
    private var cont: CheckedContinuation<Void, Error>?
    init(_ c: CheckedContinuation<Void, Error>) { cont = c }
    func resume(_ error: Error?) {
        lock.lock(); let c = cont; cont = nil; lock.unlock()
        guard let c else { return }
        if let error { c.resume(throwing: error) } else { c.resume() }
    }
}
