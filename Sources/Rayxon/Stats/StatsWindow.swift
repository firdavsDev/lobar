import SwiftUI
import Charts
import AppKit

struct StatsView: View {
    var stats: StatsStore
    var petName: String

    private var week: [DayStats] { stats.lastDays(7) }
    private var today: DayStats { stats.day(Date()) }
    private static let dayFmt: DateFormatter = { let f = DateFormatter(); f.locale = Locale(identifier: "uz_UZ"); f.dateFormat = "EE"; return f }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                tile("Bugun ish", value: hours(today.activeSeconds), symbol: "clock.fill", tint: .blue)
                tile("Pomodoro", value: "\(today.pomodoros)", symbol: "timer", tint: .red)
                tile("Suv", value: "\(today.water)", symbol: "drop.fill", tint: .cyan)
                tile("Suhbat", value: "\(today.chats)", symbol: "bubble.left.fill", tint: .purple)
            }
            GroupBox("Haftalik ish vaqti (soat)") {
                Chart(week) { d in
                    BarMark(x: .value("Kun", Self.dayFmt.string(from: d.date)), y: .value("Soat", Double(d.activeSeconds) / 3600))
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(4)
                }
                .chartYAxis { AxisMarks(position: .leading) }
                .frame(height: 150)
                .padding(.top, 4)
            }
            GroupBox("Haftalik pomodoro va suv") {
                Chart {
                    ForEach(week) { d in
                        BarMark(x: .value("Kun", Self.dayFmt.string(from: d.date)), y: .value("Soni", d.pomodoros))
                            .foregroundStyle(by: .value("Tur", "Pomodoro"))
                            .position(by: .value("Tur", "Pomodoro"))
                        BarMark(x: .value("Kun", Self.dayFmt.string(from: d.date)), y: .value("Soni", d.water))
                            .foregroundStyle(by: .value("Tur", "Suv"))
                            .position(by: .value("Tur", "Suv"))
                    }
                }
                .chartForegroundStyleScale(["Pomodoro": Color.red.gradient, "Suv": Color.cyan.gradient])
                .frame(height: 150)
                .padding(.top, 4)
            }
            Text(summary).font(.callout).foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 560)
    }

    private var summary: String {
        let total = week.reduce(0) { $0 + $1.activeSeconds }
        let pomo = week.reduce(0) { $0 + $1.pomodoros }
        return "\(petName): bu hafta \(hours(total)) ish, \(pomo) pomodoro, \(week.reduce(0) { $0 + $1.water }) marta suv eslatdim."
    }

    private func hours(_ s: Int) -> String {
        let h = s / 3600, m = (s % 3600) / 60
        return h > 0 ? "\(h) s \(m) d" : "\(m) daq"
    }

    private func tile(_ title: String, value: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol).foregroundStyle(.white).font(.system(size: 12, weight: .bold))
                .frame(width: 24, height: 24).background(tint.gradient, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            Text(value).font(.title2.weight(.semibold)).monospacedDigit()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

@MainActor
final class StatsWindowController {
    private var window: NSWindow?
    func show(stats: StatsStore, petName: String) {
        if window == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: StatsView(stats: stats, petName: petName)))
            w.title = "Statistika"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}
