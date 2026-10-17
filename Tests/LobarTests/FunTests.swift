import Testing
import Foundation
@testable import Lobar

struct ProverbsTests {
    @Test func dailyProverbIsStablePerDayAndNonEmpty() {
        let d1 = Date(timeIntervalSince1970: 1_800_000_000), d2 = d1.addingTimeInterval(3600)
        #expect(Proverbs.proverb(for: d1) == Proverbs.proverb(for: d2))
        #expect(Proverbs.proverb(for: d1) != Proverbs.proverb(for: d1.addingTimeInterval(86400)))
        #expect(Proverbs.all.count >= 30 && Proverbs.jokes.count >= 20)
    }
}

struct WeatherTests {
    @Test func parsesOpenMeteoCurrent() throws {
        let data = #"{"current":{"temperature_2m":7.5,"weather_code":61,"wind_speed_10m":12.0}}"#.data(using: .utf8)!
        let w = try Weather.parse(data)
        #expect(w.temperature == 7.5)
        #expect(w.isRaining)
        #expect(w.summaryUz.contains("yomg'ir"))
    }
    @Test func picksOutfitByTemperature() {
        #expect(Weather.suggestedOutfit(temperature: 3, available: ["atlas", "adras", "tungi"]) == "adras")
        #expect(Weather.suggestedOutfit(temperature: 33, available: ["atlas", "adras"]) == "atlas")
        #expect(Weather.suggestedOutfit(temperature: 3, available: ["atlas"]) == nil)
    }
}

struct AppWatcherTests {
    @Test func classifiesBundleIds() {
        #expect(AppWatcher.category(for: "com.microsoft.VSCode") == .coding)
        #expect(AppWatcher.category(for: "com.apple.dt.Xcode") == .coding)
        #expect(AppWatcher.category(for: "ru.keepcoder.Telegram") == .messaging)
        #expect(AppWatcher.category(for: "com.google.Chrome") == .browser)
        #expect(AppWatcher.category(for: "com.apple.Terminal") == .terminal)
        #expect(AppWatcher.category(for: "com.foo.unknown") == .other)
    }
    @Test func distractionFiresAfterTenMinutesInMessaging() {
        var w = AppWatcher()
        #expect(w.update(category: .messaging, at: 0) == .openedMessaging)
        #expect(w.update(category: .messaging, at: 9 * 60) == nil)
        #expect(w.update(category: .messaging, at: 10 * 60 + 1) == .distracted)
        #expect(w.update(category: .messaging, at: 11 * 60) == nil)       // once
        #expect(w.update(category: .coding, at: 12 * 60) == .backToWork)
    }
}

struct GamesTests {
    @Test func rockPaperScissorsOutcome() {
        #expect(Games.rps(user: .rock, pet: .scissors) == .userWins)
        #expect(Games.rps(user: .rock, pet: .paper) == .petWins)
        #expect(Games.rps(user: .paper, pet: .paper) == .draw)
    }
    @Test func whichHandIsFair() {
        var rng = SeededRNG(state: 5)
        var lefts = 0
        for _ in 0..<1000 where Games.hideHand(using: &rng) == .left { lefts += 1 }
        #expect(lefts > 400 && lefts < 600)
    }
}

struct PeerMessageTests {
    @Test func roundTripsJSON() throws {
        let m = PeerMessage(from: "Lobar", text: "Salom!", kind: .hello)
        let data = try m.encoded()
        let back = try PeerMessage.decode(data)
        #expect(back.from == "Lobar" && back.kind == .hello && back.text == "Salom!")
    }
}
