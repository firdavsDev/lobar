import Testing
import Foundation
@testable import Lobar

struct RoutineEngineTests {
    func date(_ h: Int, _ m: Int = 0, day: Int = 10) -> Date {
        var c = DateComponents(); c.year = 2026; c.month = 10; c.day = day; c.hour = h; c.minute = m
        return Calendar(identifier: .gregorian).date(from: c)!
    }

    @Test func morningGreetingOncePerDay() {
        var r = RoutineEngine()
        #expect(r.events(at: date(8)) == [.morning])
        #expect(r.events(at: date(9)) == [])
        #expect(r.events(at: date(8, day: 11)) == [.morning])
    }

    @Test func lunchAndEveningWindows() {
        var r = RoutineEngine()
        _ = r.events(at: date(7))
        #expect(r.events(at: date(12, 20)) == [])
        #expect(r.events(at: date(12, 45)) == [.lunch])
        #expect(r.events(at: date(13, 10)) == [])
        #expect(r.events(at: date(21, 30)) == [.evening])
        #expect(r.events(at: date(22)) == [])
    }

    @Test func nightModeFlag() {
        let r = RoutineEngine()
        #expect(r.isNight(at: date(23, 30)))
        #expect(r.isNight(at: date(2)))
        #expect(!r.isNight(at: date(9)))
    }

    @Test func userIdleThresholds() {
        var r = RoutineEngine()
        #expect(r.idleEvent(secondsIdle: 100) == nil)
        #expect(r.idleEvent(secondsIdle: 11 * 60) == .userAway)
        #expect(r.idleEvent(secondsIdle: 12 * 60) == nil)          // once
        #expect(r.idleEvent(secondsIdle: 31 * 60) == .userGone)
        #expect(r.idleEvent(secondsIdle: 5) == .userBack)
        #expect(r.idleEvent(secondsIdle: 5) == nil)
    }
}
