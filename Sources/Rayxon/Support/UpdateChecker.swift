import Foundation

/// Minimal update check against GitHub Releases. Replace with Sparkle once a Developer ID + EdDSA key exist.
enum UpdateChecker {
    struct Release: Sendable { var version: String; var pageURL: URL; var downloadURL: URL }
    static let repo = "firdavsDev/rayxon"      // owner/repo on GitHub

    static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }

    static func isNewer(_ a: String, than b: String) -> Bool {
        func parts(_ s: String) -> [Int] {
            s.trimmingCharacters(in: CharacterSet(charactersIn: "vV")).split(separator: ".").map { Int($0) ?? 0 }
        }
        let x = parts(a), y = parts(b)
        for i in 0..<max(x.count, y.count) {
            let l = i < x.count ? x[i] : 0, r = i < y.count ? y[i] : 0
            if l != r { return l > r }
        }
        return false
    }

    static func parse(_ data: Data) throws -> Release {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String,
              let page = (json["html_url"] as? String).flatMap(URL.init(string:)) else {
            throw LLMError.badResponse("release json")
        }
        let assets = json["assets"] as? [[String: Any]] ?? []
        let dmg = assets.first { ($0["name"] as? String)?.hasSuffix(".dmg") == true }?["browser_download_url"] as? String
        return Release(version: tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV")), pageURL: page,
                       downloadURL: dmg.flatMap(URL.init(string:)) ?? page)
    }

    /// Returns a newer release if one exists.
    static func check() async throws -> Release? {
        var req = URLRequest(url: URL(string: "https://api.github.com/repos/\(repo)/releases/latest")!)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let data = try await LLMHTTP.send(req)
        let r = try parse(data)
        return isNewer(r.version, than: currentVersion) ? r : nil
    }
}
