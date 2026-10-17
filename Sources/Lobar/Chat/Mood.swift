import Foundation

/// Capricious-girl affection model. Persisted as a single number; tone drives phrase choice.
struct Mood: Sendable, Equatable {
    enum Tone: Sendable { case sulky, sassy, sweet }
    enum PatResult: Sendable { case pleased, annoyed }

    var affection: Double                   // 0...100
    private var patTimes: [Double] = []
    private var clickTimes: [Double] = []

    init(affection: Double = 50) { self.affection = min(100, max(0, affection)) }

    var tone: Tone {
        if affection < 30 { return .sulky }
        if affection < 75 { return .sassy }
        return .sweet
    }

    mutating func headPat(at t: Double) -> PatResult {
        patTimes.append(t)
        patTimes.removeAll { t - $0 > 60 }
        if patTimes.count > 3 {
            affection = max(0, affection - 2)
            return .annoyed
        }
        affection = min(100, affection + 5 / Double(patTimes.count))
        return .pleased
    }

    mutating func chatted() { affection = min(100, affection + 3) }
    mutating func shaken(at t: Double) { affection = max(0, affection - 6) }
    mutating func taskDone() { affection = min(100, affection + 4) }
    mutating func reminderIgnored() { affection = max(0, affection - 1) }

    /// Neglect: roughly -1 per 2 hours, floor at 20 so she never fully gives up.
    mutating func decay(hoursSinceLastInteraction: Double) {
        guard hoursSinceLastInteraction > 1 else { return }
        affection = max(20, affection - hoursSinceLastInteraction / 2)
    }

    /// True when the user clicks her too fast too often.
    mutating func clicked(at t: Double) -> Bool {
        clickTimes.append(t)
        clickTimes.removeAll { t - $0 > 2.5 }
        if clickTimes.count >= 6 { clickTimes.removeAll(); return true }
        return false
    }
}
