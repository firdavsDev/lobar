import Foundation

enum Birthday {
    private static let cal = Calendar(identifier: .gregorian)
    static func isToday(birthday: Date, now: Date = Date()) -> Bool {
        let b = cal.dateComponents([.month, .day], from: birthday)
        let n = cal.dateComponents([.month, .day], from: now)
        return b.month == n.month && b.day == n.day
    }
    static func age(birthday: Date, now: Date = Date()) -> Int {
        cal.dateComponents([.year], from: birthday, to: now).year ?? 0
    }
}
