import Foundation

enum ReminderKind: String, CaseIterable, Sendable, Hashable {
    case water, eyes, posture
}

/// Pure interval scheduler with pause/resume (screen lock, sleep).
struct ReminderScheduler: Sendable {
    private var intervals: [ReminderKind: Double] = [:]   // seconds
    private var nextDue: [ReminderKind: Double] = [:]
    private var pausedAt: Double?
    private var pauseReasons: Set<String> = []

    mutating func configure(_ minutes: [ReminderKind: Int], at t: Double) {
        intervals = minutes.mapValues { Double($0 * 60) }
        nextDue = intervals.mapValues { t + $0 }
    }

    mutating func pause(at t: Double, reason: String = "default") {
        pauseReasons.insert(reason)
        if pausedAt == nil { pausedAt = t }
    }

    mutating func resume(at t: Double, reason: String = "default") {
        pauseReasons.remove(reason)
        guard pauseReasons.isEmpty, let p = pausedAt else { return }
        let shift = t - p
        for k in nextDue.keys { nextDue[k]! += shift }
        pausedAt = nil
    }

    /// Reminders that are due now, earliest-due first; each is rescheduled.
    mutating func due(at t: Double) -> [ReminderKind] {
        guard pausedAt == nil else { return [] }
        let ready = ReminderKind.allCases.compactMap { k -> (ReminderKind, Double)? in
            guard let d = nextDue[k], t >= d else { return nil }
            return (k, d)
        }.sorted { $0.1 < $1.1 }
        for (k, _) in ready { nextDue[k] = t + intervals[k]! }
        return ready.map { $0.0 }
    }
}
