import Testing
import Foundation
@testable import Rayxon

struct EdgeTTSTests {
    @Test func buildsUvToolRunArguments() {
        let args = EdgeTTSCLIEngine.arguments(voice: "uz-UZ-MadinaNeural", text: "Salom", output: URL(fileURLWithPath: "/tmp/x.mp3"), latest: false)
        #expect(args == ["tool", "run", "--from", "edge-tts", "edge-tts", "--voice", "uz-UZ-MadinaNeural", "--text", "Salom", "--write-media", "/tmp/x.mp3"])
    }

    @Test func latestFlagForcesUpgradeAfter403() {
        let args = EdgeTTSCLIEngine.arguments(voice: "v", text: "t", output: URL(fileURLWithPath: "/tmp/x.mp3"), latest: true)
        #expect(args.contains("edge-tts@latest"))
    }

    @Test func detectsAuthFailureInStderr() {
        #expect(EdgeTTSCLIEngine.looksLikeAuthFailure("aiohttp WSServerHandshakeError: 403, message='Invalid response status'"))
        #expect(!EdgeTTSCLIEngine.looksLikeAuthFailure("network unreachable"))
    }

    @Test func stripsMarkupBeforeSpeaking() {
        #expect(EdgeTTSCLIEngine.sanitize("Salom **do'st**! `kod` \n yangi qator") == "Salom do'st! kod yangi qator")
    }
}
