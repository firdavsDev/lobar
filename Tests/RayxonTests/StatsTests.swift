import Testing
import Foundation
@testable import Rayxon

@MainActor
struct StatsStoreTests {
    func temp() -> StatsStore {
        StatsStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("rayxon-stats-\(UUID()).json"))
    }
    func day(_ d: Int) -> Date {
        var c = DateComponents(); c.year = 2026; c.month = 10; c.day = d; c.hour = 12
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    @Test func recordsPerDayAndPersists() {
        let s = temp()
        s.record(.pomodoro, at: day(10))
        s.record(.pomodoro, at: day(10))
        s.record(.water, at: day(10))
        s.addActive(seconds: 90, at: day(10))
        s.record(.pomodoro, at: day(11))
        #expect(s.day(day(10)).pomodoros == 2)
        #expect(s.day(day(10)).water == 1)
        #expect(s.day(day(10)).activeSeconds == 90)
        #expect(s.day(day(11)).pomodoros == 1)
        let reloaded = StatsStore(fileURL: s.fileURL)
        #expect(reloaded.day(day(10)).pomodoros == 2)
    }

    @Test func weekSeriesHasSevenEntriesEndingToday() {
        let s = temp()
        s.record(.chat, at: day(9))
        let week = s.lastDays(7, ending: day(12))
        #expect(week.count == 7)
        #expect(week.last?.date == Calendar(identifier: .gregorian).startOfDay(for: day(12)))
        #expect(week[3].chats == 1)      // day 9 is the 4th of [6,7,8,9,10,11,12]
    }
}
