import Testing
import Foundation
import CoreGraphics
@testable import Lobar

struct ReviewFixTests {
    @Test func bodyBelowFloorSnapsToFloor() {
        var body = Body(x: 0, y: -40, vx: 0, vy: 0)
        let landed = Physics.step(&body, dt: 0.1, supports: [], floorY: 0)
        #expect(landed == .floor)
        #expect(body.y == 0)
    }

    @Test func geminiIgnoresThoughtParts() throws {
        let data = #"{"candidates":[{"content":{"parts":[{"text":"secret reasoning","thought":true},{"text":"Salom!"}]}}]}"#.data(using: .utf8)!
        #expect(try GeminiProvider.parse(data) == "Salom!")
    }

    @Test func pomodoroPauseShiftsDeadline() {
        var p = PomodoroEngine(workMinutes: 10, breakMinutes: 5)
        p.start(at: 0)
        p.pause(at: 5 * 60)
        #expect(p.tick(at: 20 * 60) == nil)          // paused: nothing fires
        p.resume(at: 20 * 60)
        #expect(p.tick(at: 24 * 60) == nil)
        #expect(p.tick(at: 25 * 60) == .breakStarted)
    }

    @Test func schedulerPauseIsReferenceCounted() {
        var s = ReminderScheduler()
        s.configure([.water: 10], at: 0)
        s.pause(at: 60, reason: "lock")
        s.pause(at: 60, reason: "sleep")
        s.resume(at: 120, reason: "sleep")
        #expect(s.due(at: 700).isEmpty)              // still paused by lock
        s.resume(at: 180, reason: "lock")
        #expect(s.due(at: 10 * 60 + 120 - 1).isEmpty)
        #expect(s.due(at: 10 * 60 + 120) == [.water])
    }

    @Test func smallWindowsStillOccludeEdgesBelow() {
        let tiny = RawWindow(number: 1, pid: 1, layer: 0, alpha: 1, bounds: CGRect(x: 100, y: 50, width: 80, height: 500))
        let back = RawWindow(number: 2, pid: 1, layer: 0, alpha: 1, bounds: CGRect(x: 0, y: 200, width: 400, height: 300))
        let out = SurfaceModel.supports(from: [tiny, back], primaryHeight: 1000, selfPID: 0, isRegularApp: { _ in true })
        #expect(!out.contains { $0.id == .window(1) })          // too small to stand on
        let backs = out.filter { $0.id == .window(2) }
        #expect(backs.count == 2)                                // but it still hides part of the back edge
    }

    @Test func authFailureDetectionIsStrict() {
        #expect(EdgeTTSCLIEngine.looksLikeAuthFailure("WSServerHandshakeError: 403, message='Invalid response status'"))
        #expect(!EdgeTTSCLIEngine.looksLikeAuthFailure("wrote 4031 bytes to file"))
    }
}

@MainActor
struct ReviewFixMainTests {
    @Test func memoryGenerationRejectsStaleAdds() {
        let store = MemoryStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("lobar-gen-\(UUID()).json"))
        let gen = store.generation
        store.clear()
        store.add(["stale"], ifGeneration: gen)
        #expect(store.facts.isEmpty)
        store.add(["fresh"], ifGeneration: store.generation)
        #expect(store.facts == ["fresh"])
    }
}
