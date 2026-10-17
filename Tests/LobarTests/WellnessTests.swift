import Testing
import Foundation
@testable import Lobar

struct PomodoroEngineTests {
    @Test func startsInWorkAndTransitionsToBreak() {
        var p = PomodoroEngine(workMinutes: 30, breakMinutes: 10)
        p.start(at: 0)
        #expect(p.phase == .work)
        #expect(p.tick(at: 29 * 60) == nil)
        #expect(p.tick(at: 30 * 60) == .breakStarted)
        #expect(p.phase == .breakTime)
        #expect(p.tick(at: 40 * 60) == .workStarted)
        #expect(p.phase == .work)
    }

    @Test func stopResetsToIdle() {
        var p = PomodoroEngine(workMinutes: 30, breakMinutes: 10)
        p.start(at: 0); p.stop()
        #expect(p.phase == .idle)
        #expect(p.tick(at: 100_000) == nil)
    }

    @Test func remainingSecondsCountsDown() {
        var p = PomodoroEngine(workMinutes: 1, breakMinutes: 1)
        p.start(at: 0)
        #expect(p.remaining(at: 15) == 45)
    }
}

struct ReminderSchedulerTests {
    @Test func firesEachReminderWhenDue() {
        var s = ReminderScheduler()
        s.configure([.water: 45, .eyes: 20, .posture: 60], at: 0)
        #expect(s.due(at: 19 * 60).isEmpty)
        #expect(s.due(at: 20 * 60) == [.eyes])
        #expect(s.due(at: 20 * 60).isEmpty)          // consumed
        #expect(s.due(at: 45 * 60) == [.eyes, .water])
    }

    @Test func pauseShiftsSchedule() {
        var s = ReminderScheduler()
        s.configure([.water: 10], at: 0)
        s.pause(at: 5 * 60)
        s.resume(at: 65 * 60)
        #expect(s.due(at: 69 * 60).isEmpty)
        #expect(s.due(at: 70 * 60) == [.water])
    }

    @Test func disabledKindsNeverFire() {
        var s = ReminderScheduler()
        s.configure([.water: 10], at: 0)
        #expect(s.due(at: 1_000_000) == [.water])
        #expect(s.due(at: 2_000_000) == [.water])
        s.configure([:], at: 2_000_000)
        #expect(s.due(at: 9_000_000).isEmpty)
    }
}
