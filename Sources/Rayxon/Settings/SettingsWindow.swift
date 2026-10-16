import SwiftUI
import AppKit

enum SettingsPane: String, CaseIterable, Identifiable {
    case general, character, chat, voice, reminders, fun
    var id: String { rawValue }
    var title: String {
        switch self {
        case .general: return "Umumiy"
        case .character: return "Qahramon"
        case .chat: return "Suhbat"
        case .voice: return "Ovoz"
        case .reminders: return "Eslatmalar"
        case .fun: return "Qiziqarli"
        }
    }
    var symbol: String {
        switch self {
        case .general: return "gearshape.fill"
        case .character: return "face.smiling.inverse"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .voice: return "speaker.wave.2.fill"
        case .reminders: return "bell.badge.fill"
        case .fun: return "sparkles"
        }
    }
    var tint: Color {
        switch self {
        case .general: return .gray
        case .character: return .pink
        case .chat: return .blue
        case .voice: return .orange
        case .reminders: return .green
        case .fun: return .indigo
        }
    }
}

struct SettingsView: View {
    @Bindable var settings: SettingsStore
    var voices: [(id: String, title: String)]
    var onTestVoice: () -> Void
    @Binding var pane: SettingsPane
    @State private var fetchedModels: [LLMProviderKind: [String]] = [:]
    @State private var fetchStatus: String? = nil

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detail
        }
        .frame(minWidth: 720, minHeight: 500)
    }

    // MARK: Sidebar

    var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Spacer().frame(height: 36)   // room for traffic lights
            ForEach(SettingsPane.allCases) { p in
                Button { pane = p } label: {
                    HStack(spacing: 10) {
                        Image(systemName: p.symbol)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 26, height: 26)
                            .background(p.tint.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                        Text(p.title).font(.system(size: 13, weight: pane == p ? .semibold : .regular))
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(pane == p ? Color.accentColor.opacity(0.22) : .clear,
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Text("Rayxon 0.1").font(.caption2).foregroundStyle(.tertiary).padding(.horizontal, 12)
        }
        .padding(10)
        .frame(width: 200)
        .background(.ultraThinMaterial)
    }

    // MARK: Detail

    var detail: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: pane.symbol)
                    .font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(pane.tint.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(pane.title).font(.title2.weight(.semibold))
                    Text(subtitle).font(.callout).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 24).padding(.top, 36).padding(.bottom, 8)
            Group {
                switch pane {
                case .general: general
                case .character: character
                case .chat: chat
                case .voice: voice
                case .reminders: reminders
                case .fun: fun
                }
            }
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var subtitle: String {
        switch pane {
        case .general: return "Siz haqingizda va umumiy xatti-harakat"
        case .character: return "Ism, munosabat, o'lcham, dialog oynasi"
        case .chat: return "Suhbat uchun AI provayder va model"
        case .voice: return "O'zbekcha ovoz (Edge TTS)"
        case .reminders: return "Sog'liq eslatmalari va Pomodoro"
        case .fun: return "Ob-havo, ilovalarga reaksiya, git, o'yinlar"
        }
    }

    // MARK: Panes

    var general: some View {
        Form {
            Section {
                TextField("Ismingiz", text: $settings.userName, prompt: Text("ixtiyoriy"))
                Toggle("O'zi gapirib tursin", isOn: $settings.chatterEnabled)
                Toggle("Gaplarni AI yozsin (kalit bo'lsa)", isOn: $settings.llmChatter).disabled(!settings.chatterEnabled)
                Toggle("Tungi rejim (23:00–06:00 uxlaydi)", isOn: $settings.nightMode)
            } footer: {
                Text("U sizni shu ism bilan chaqiradi va har 5–12 daqiqada o'zi gap boshlaydi. AI yoqilsa gaplar har safar yangi bo'ladi.")
            }
            Section("Tovushlar") {
                Toggle("Ovoz (gapirish)", isOn: $settings.voiceEnabled)
                Toggle("Effektlar (yiqilish, silash, uyqu)", isOn: $settings.sfxEnabled)
            }
            Section("Kayfiyat") {
                HStack(spacing: 10) {
                    Image(systemName: settings.affection < 30 ? "cloud.rain.fill" : (settings.affection < 75 ? "cloud.sun.fill" : "sun.max.fill"))
                        .foregroundStyle(settings.affection < 30 ? .blue : (settings.affection < 75 ? .orange : .yellow))
                    Text(settings.affection < 30 ? "Xafa" : (settings.affection < 75 ? "Injiq" : "Xursand"))
                    Spacer()
                    ProgressView(value: settings.affection, total: 100).frame(width: 160)
                    Text("\(Int(settings.affection))").monospacedDigit().foregroundStyle(.secondary)
                }
                Text("Boshini silang, gaplashing — ko'tariladi. Silkitsangiz, unutsangiz — tushadi.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    var character: some View {
        Form {
            Section("Ism") {
                TextField("Qahramon ismi", text: $settings.petName, prompt: Text("Rayxon"))
            }
            Section {
                Picker("Munosabat", selection: $settings.relationship) {
                    ForEach(Relationship.allCases) { r in Label(r.title, systemImage: r.symbol).tag(r) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } header: { Text("Munosabat") } footer: {
                Text(settings.relationship.blurb)
            }
            Section("O'lcham va dialog") {
                sliderRow("Qahramon o'lchami", value: $settings.petScale, range: 0.6...1.6, step: 0.1) { "\(Int($0 * 100))%" }
                sliderRow("Dialog kengligi", value: $settings.bubbleWidth, range: 160...420, step: 10) { "\(Int($0)) pt" }
                sliderRow("Dialog shrifti", value: $settings.bubbleFontSize, range: 10...20, step: 1) { "\(Int($0)) pt" }
            }
        }
    }

    func sliderRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: @escaping (Double) -> String) -> some View {
        LabeledContent(title) {
            HStack(spacing: 10) {
                Slider(value: value, in: range, step: step).frame(width: 170)
                Text(format(value.wrappedValue)).monospacedDigit().foregroundStyle(.secondary).frame(width: 52, alignment: .trailing)
            }
        }
    }

    var chat: some View {
        Form {
            Section {
                Picker("Provayder", selection: $settings.provider) {
                    ForEach(LLMProviderKind.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            } header: { Text("Provayder") } footer: {
                Text("Faqat tanlangan provayderga so'rov yuboriladi. Kalitlar Keychain'da.")
            }
            providerSection(settings.provider)
        }
    }

    @ViewBuilder
    func providerSection(_ kind: LLMProviderKind) -> some View {
        let keyBinding: Binding<String> = {
            switch kind {
            case .gemini: return $settings.geminiKey
            case .claude: return $settings.claudeKey
            case .openai: return $settings.openaiKey
            }
        }()
        let modelBinding = Binding<String>(get: { settings.model(for: kind) }, set: { settings.setModel($0, for: kind) })
        let options = Array(Set((fetchedModels[kind] ?? []) + kind.suggestedModels + [settings.model(for: kind)])).sorted()
        let hasKey = !settings.key(for: kind).isEmpty
        Section {
            SecureField("API kalit", text: keyBinding, prompt: Text(kind == .openai ? "sk-…" : (kind == .claude ? "sk-ant-…" : "AIza…")))
            if kind == .openai {
                TextField("Base URL", text: $settings.openaiBaseURL, prompt: Text(OpenAIProvider.defaultBaseURL))
            }
            Link(destination: URL(string: kind.keyURL)!) { Label("Kalit olish", systemImage: "arrow.up.right.square") }
        } header: {
            HStack {
                Text("\(kind.title) kaliti")
                Spacer()
                Label(hasKey ? "kiritilgan" : "kiritilmagan", systemImage: hasKey ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .font(.caption).foregroundStyle(hasKey ? .green : .orange)
            }
        } footer: {
            if kind == .openai { Text("OpenAI-mos serverlar ham ishlaydi: Ollama (http://localhost:11434/v1), Groq, OpenRouter.") }
        }
        Section {
            Picker("Model", selection: modelBinding) {
                ForEach(options, id: \.self) { Text($0).tag($0) }
            }
            TextField("Boshqa model (qo'lda)", text: modelBinding)
            HStack {
                Button {
                    fetchStatus = "Yuklanmoqda…"
                    Task {
                        do {
                            let list = try await ModelCatalog.fetch(kind, apiKey: settings.key(for: kind), baseURL: settings.openaiBaseURL)
                            fetchedModels[kind] = list
                            fetchStatus = "\(list.count) ta model topildi"
                        } catch let e as LLMError { fetchStatus = e.userMessage } catch { fetchStatus = error.localizedDescription }
                    }
                } label: { Label("Modellarni yuklash", systemImage: "arrow.clockwise") }
                .disabled(!hasKey && kind != .openai)
                if let fetchStatus { Text(fetchStatus).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
            }
        } header: { Text("Model") } footer: {
            Text("Ro'yxatdan tanlang yoki model nomini qo'lda yozing. \"Modellarni yuklash\" provayderdan joriy ro'yxatni oladi.")
        }
    }

    var voice: some View {
        Form {
            Section {
                Toggle("Ovoz yoqilgan", isOn: $settings.voiceEnabled)
                Picker("Ovoz", selection: $settings.voiceName) {
                    ForEach(voices, id: \.id) { Text($0.title).tag($0.id) }
                }
                LabeledContent("Balandlik") {
                    HStack {
                        Image(systemName: "speaker.fill").foregroundStyle(.secondary)
                        Slider(value: $settings.volume, in: 0...1).frame(width: 160)
                        Image(systemName: "speaker.wave.3.fill").foregroundStyle(.secondary)
                    }
                }
                Button { onTestVoice() } label: { Label("Sinab ko'rish", systemImage: "play.fill") }
            } footer: {
                Text("Microsoft Edge TTS orqali bepul o'zbek ovozi (Madina / Sardor). Internet kerak.")
            }
        }
    }

    var reminders: some View {
        Form {
            reminderCard("Suv ichish", symbol: "drop.fill", tint: .blue, enabled: $settings.waterEnabled, minutes: $settings.waterMinutes,
                         note: "Kofe hisobga kirmaydi.")
            reminderCard("Ko'zga dam", symbol: "eye.fill", tint: .teal, enabled: $settings.eyesEnabled, minutes: $settings.eyesMinutes,
                         note: "20-20-20 qoidasi: har 20 daqiqada 20 soniya 6 metr narini ko'ring.")
            reminderCard("Qomat va cho'zilish", symbol: "figure.walk", tint: .purple, enabled: $settings.postureEnabled, minutes: $settings.postureMinutes,
                         note: "Turing, yelkani bo'shashtiring, bir daqiqa yuring.")
            Section {
                Stepper(value: $settings.pomodoroWork, in: 5...120, step: 5) {
                    LabeledContent("Ish", value: "\(settings.pomodoroWork) daqiqa")
                }
                Stepper(value: $settings.pomodoroBreak, in: 1...60) {
                    LabeledContent("Tanaffus", value: "\(settings.pomodoroBreak) daqiqa")
                }
            } header: {
                Label("Pomodoro", systemImage: "timer")
            } footer: {
                Text("O'ng tugma menyusidan boshlanadi. Vazifalarga vaqt qo'ysangiz, u ham eslatadi.")
            }
        }
    }

    var fun: some View {
        Form {
            Section {
                Toggle("Ob-havo haqida gapirsin (Toshkent)", isOn: $settings.weatherEnabled)
                Toggle("Havoga qarab kiyim almashtirsin", isOn: $settings.weatherOutfit).disabled(!settings.weatherEnabled)
            } header: { Text("Ob-havo") } footer: { Text("Open-Meteo, kalit kerak emas. Sovuqda chapan, issiqda atlas.") }
            Section {
                Toggle("Ilovalarga reaksiya (kod, Telegram, chalg'ish)", isOn: $settings.appReactions)
                TextField("Loyihalar papkasi (git commit kuzatuv)", text: $settings.projectsFolder, prompt: Text("~/Desktop/Programming"))
            } header: { Text("Ish") } footer: { Text("Papka ichidagi repolarda yangi commit bo'lsa xursand bo'ladi. Faqat .git/logs/HEAD vaqtini o'qiydi.") }
            Section {
                Toggle("Qiziq hodisalar (yashirinish, kursor quvish, non, mushuk, parashyut)", isOn: $settings.funEvents)
                Toggle("Tarmoqdagi boshqa Rayxonlar bilan salomlashsin", isOn: $settings.lanPeers)
            } header: { Text("Hodisalar") } footer: { Text("Ikki marta bossangiz — non tushadi. O'yinlar: o'ng tugma → O'ynaymizmi?") }
        }
    }

    func reminderCard(_ title: String, symbol: String, tint: Color, enabled: Binding<Bool>, minutes: Binding<Int>, note: String) -> some View {
        Section {
            Toggle("Yoqilgan", isOn: enabled)
            Stepper(value: minutes, in: 5...180, step: 5) {
                LabeledContent("Oraliq", value: "har \(minutes.wrappedValue) daqiqa")
            }
            .disabled(!enabled.wrappedValue)
        } header: {
            HStack(spacing: 8) {
                Image(systemName: symbol).foregroundStyle(.white).font(.system(size: 11, weight: .bold))
                    .frame(width: 22, height: 22).background(tint.gradient, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text(title)
            }
        } footer: {
            Text(note)
        }
    }
}

@MainActor @Observable final class PaneModel { var pane: SettingsPane = .general }

struct SettingsRoot: View {
    @Bindable var model: PaneModel
    var settings: SettingsStore
    var voices: [(id: String, title: String)]
    var onTestVoice: () -> Void
    var body: some View { SettingsView(settings: settings, voices: voices, onTestVoice: onTestVoice, pane: $model.pane) }
}

@MainActor
final class SettingsWindowController {
    private var window: NSWindow?
    var debugWindow: NSWindow? { window }
    private let paneModel = PaneModel()
    func debugSelect(_ p: SettingsPane) { paneModel.pane = p }
    private var observer: NSObjectProtocol?
    private var pollTimer: Timer?
    private var onChange: () -> Void = {}

    func show(settings: SettingsStore, voices: [(id: String, title: String)], onTestVoice: @escaping () -> Void,
              onChange: @escaping () -> Void) {
        self.onChange = onChange
        if window == nil {
            let model = paneModel
            let host = NSHostingController(rootView: SettingsRoot(model: model, settings: settings, voices: voices, onTestVoice: onTestVoice))
            let w = NSWindow(contentViewController: host)
            w.title = "Sozlamalar"
            w.styleMask = [.titled, .closable, .fullSizeContentView]
            w.titlebarAppearsTransparent = true
            w.toolbarStyle = .unified
            w.isReleasedWhenClosed = false
            w.setContentSize(NSSize(width: 760, height: 540))
            w.center()
            window = w
            observer = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: w, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.onChange() }
            }
        }
        pollTimer?.invalidate()
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.window?.isVisible == true else { self?.pollTimer?.invalidate(); return }
                self.onChange()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        pollTimer = t
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}
