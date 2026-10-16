import Foundation

/// Day rhythm: one-shot greetings per day, night mode, and user idle/away detection. Pure and testable.
struct RoutineEngine: Sendable {
    enum Event: Sendable, Equatable { case morning, lunch, evening, userAway, userGone, userBack }

    private var firedDay: [Event: Int] = [:]      // event → day-of-year it fired
    private var awayState = 0                     // 0 present, 1 away announced, 2 gone announced
    private let cal = Calendar(identifier: .gregorian)

    init() {}

    mutating func events(at now: Date) -> [Event] {
        let day = cal.ordinality(of: .day, in: .year, for: now) ?? 0
        let h = cal.component(.hour, from: now), m = cal.component(.minute, from: now)
        let minutes = h * 60 + m
        var out: [Event] = []
        func once(_ e: Event, _ cond: Bool) {
            if cond, firedDay[e] != day { firedDay[e] = day; out.append(e) }
        }
        once(.morning, minutes >= 6 * 60 && minutes < 12 * 60)
        once(.lunch, minutes >= 12 * 60 + 30 && minutes < 13 * 60 + 30)
        once(.evening, minutes >= 21 * 60 && minutes < 24 * 60)
        return out
    }

    func isNight(at now: Date) -> Bool {
        let h = cal.component(.hour, from: now)
        return h >= 23 || h < 6
    }

    /// Idle thresholds: 10 min → away (once), 30 min → gone (once), activity → back (once after away/gone).
    mutating func idleEvent(secondsIdle: Double) -> Event? {
        if secondsIdle >= 30 * 60 {
            if awayState < 2 { awayState = 2; return .userGone }
            return nil
        }
        if secondsIdle >= 10 * 60 {
            if awayState < 1 { awayState = 1; return .userAway }
            return nil
        }
        if awayState > 0 { awayState = 0; return .userBack }
        return nil
    }
}
