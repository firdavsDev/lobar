import Testing
import Foundation
@testable import Rayxon

struct UpdateCheckTests {
    @Test func comparesSemanticVersions() {
        #expect(UpdateChecker.isNewer("0.2.0", than: "0.1.0"))
        #expect(UpdateChecker.isNewer("v1.0.0", than: "0.9.9"))
        #expect(!UpdateChecker.isNewer("0.1.0", than: "0.1.0"))
        #expect(!UpdateChecker.isNewer("0.1.0", than: "0.1.1"))
    }

    @Test func parsesGitHubRelease() throws {
        let data = #"{"tag_name":"v0.3.0","html_url":"https://github.com/x/rayxon/releases/tag/v0.3.0","assets":[{"name":"Rayxon-0.3.0.dmg","browser_download_url":"https://github.com/x/rayxon/releases/download/v0.3.0/Rayxon-0.3.0.dmg"}]}"#.data(using: .utf8)!
        let r = try UpdateChecker.parse(data)
        #expect(r.version == "0.3.0")
        #expect(r.downloadURL.absoluteString.hasSuffix(".dmg"))
    }
}
