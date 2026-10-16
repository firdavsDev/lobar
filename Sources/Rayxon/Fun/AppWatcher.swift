import Foundation

/// Classifies the frontmost app and detects long distraction streaks. Pure; fed by NSWorkspace notifications.
struct AppWatcher: Sendable {
    enum Category: Sendable, Equatable { case coding, terminal, browser, messaging, media, other }
    enum Event: Sendable, Equatable { case distracted, backToWork, startedCoding, openedMessaging }

    static let distractionSeconds: Double = 10 * 60

    private var current: Category = .other
    private var since: Double = 0
    private var announced = false
    private var lastCodingAnnounce: Double = -1e9

    static func category(for bundleID: String) -> Category {
        let b = bundleID.lowercased()
        if b.contains("vscode") || b.contains("xcode") || b.contains("jetbrains") || b.contains("intellij") || b.contains("cursor")
            || b.contains("zed") || b.contains("sublime") || b.contains("nova") || b.contains("webstorm") || b.contains("pycharm") { return .coding }
        if b.contains("terminal") || b.contains("iterm") || b.contains("warp") || b.contains("ghostty") || b.contains("alacritty") || b.contains("kitty") { return .terminal }
        if b.contains("telegram") || b.contains("whatsapp") || b.contains("messages") || b.contains("slack") || b.contains("discord") || b.contains("mobilesms") { return .messaging }
        if b.contains("chrome") || b.contains("safari") || b.contains("firefox") || b.contains("arc") || b.contains("brave") { return .browser }
        if b.contains("spotify") || b.contains("music") || b.contains("tv") || b.contains("vlc") || b.contains("youtube") { return .media }
        return .other
    }

    mutating func update(category: Category, at t: Double) -> Event? {
        if category != current {
            let previous = current
            current = category; since = t
            let wasAnnounced = announced
            announced = false
            if wasAnnounced, category == .coding || category == .terminal { return .backToWork }
            if category == .messaging, previous != .messaging { return .openedMessaging }
            if category == .coding, t - lastCodingAnnounce > 3600 { lastCodingAnnounce = t; return .startedCoding }
            return nil
        }
        if (category == .messaging || category == .media || category == .browser), !announced, t - since >= Self.distractionSeconds {
            announced = true
            return .distracted
        }
        return nil
    }
}
