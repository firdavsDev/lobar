import Foundation

/// Pure work/break state machine driven by timestamps (seconds).
struct PomodoroEngine: Sendable, Equatable {
    enum Phase: Sendable { case idle, work, breakTime }
    enum Transition: Sendable, Equatable { case workStarted, breakStarted }

    var workMinutes: Int
    var breakMinutes: Int
    private(set) var phase: Phase = .idle
    private(set) var phaseEndsAt: Double = 0

    init(workMinutes: Int, breakMinutes: Int) {
        self.workMinutes = workMinutes
        self.breakMinutes = breakMinutes
    }

    var isRunning: Bool { phase != .idle }
    private var pausedAt: Double?

    mutating func pause(at t: Double) { if phase != .idle, pausedAt == nil { pausedAt = t } }
    mutating func resume(at t: Double) {
        guard let p = pausedAt else { return }
        phaseEndsAt += t - p
        pausedAt = nil
    }

    mutating func start(at t: Double) {
        phase = .work
        phaseEndsAt = t + Double(workMinutes * 60)
    }

    mutating func stop() {
        phase = .idle
        phaseEndsAt = 0
        pausedAt = nil
    }

    mutating func tick(at t: Double) -> Transition? {
        guard phase != .idle, pausedAt == nil, t >= phaseEndsAt else { return nil }
        switch phase {
        case .work:
            phase = .breakTime
            phaseEndsAt = t + Double(breakMinutes * 60)
            return .breakStarted
        case .breakTime:
            phase = .work
            phaseEndsAt = t + Double(workMinutes * 60)
            return .workStarted
        case .idle:
            return nil
        }
    }

    func remaining(at t: Double) -> Int { max(0, Int((phaseEndsAt - t).rounded())) }
}
