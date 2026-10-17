import Foundation
import Observation

struct DayStats: Codable, Equatable, Sendable, Identifiable {
    var date: Date                 // start of day
    var activeSeconds: Int = 0
    var pomodoros: Int = 0
    var water: Int = 0
    var eyes: Int = 0
    var posture: Int = 0
    var chats: Int = 0
    var tasksDone: Int = 0
    var id: Date { date }
}

/// Per-day counters persisted as JSON; drives the Statistika window.
@MainActor
@Observable
final class StatsStore {
    enum Metric { case pomodoro, water, eyes, posture, chat, taskDone }

    let fileURL: URL
    private(set) var days: [Date: DayStats] = [:]
    private let cal = Calendar(identifier: .gregorian)

    init(fileURL: URL) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL) {
            let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
            if let list = try? dec.decode([DayStats].self, from: data) {
                days = Dictionary(uniqueKeysWithValues: list.map { ($0.date, $0) })
            }
        }
    }

    func day(_ date: Date) -> DayStats {
        let key = cal.startOfDay(for: date)
        return days[key] ?? DayStats(date: key)
    }

    func record(_ m: Metric, at date: Date = Date()) {
        var d = day(date)
        switch m {
        case .pomodoro: d.pomodoros += 1
        case .water: d.water += 1
        case .eyes: d.eyes += 1
        case .posture: d.posture += 1
        case .chat: d.chats += 1
        case .taskDone: d.tasksDone += 1
        }
        days[d.date] = d
        save()
    }

    func addActive(seconds: Int, at date: Date = Date()) {
        var d = day(date)
        d.activeSeconds += seconds
        days[d.date] = d
        if d.activeSeconds % 60 < seconds { save() }   // persist roughly once a minute
    }

    func lastDays(_ n: Int, ending: Date = Date()) -> [DayStats] {
        let end = cal.startOfDay(for: ending)
        return (0..<n).reversed().compactMap { i in
            cal.date(byAdding: .day, value: -i, to: end).map { day($0) }
        }
    }

    private func save() {
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
        let keep = days.values.filter { $0.date > cal.date(byAdding: .day, value: -90, to: Date())! }
        if let data = try? enc.encode(Array(keep)) { try? data.write(to: fileURL, options: .atomic) }
    }
}
