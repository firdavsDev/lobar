import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// Chat transcript + memory facts, with export/import of memory.
struct HistoryView: View {
    var session: ChatSession
    var memory: MemoryStore
    var petName: String
    var onMemoryChanged: () -> Void
    @State private var status: String?

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Suhbat").font(.headline)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(session.history.messages.enumerated()), id: \.offset) { i, m in
                                HStack {
                                    if m.role == .user { Spacer(minLength: 40) }
                                    Text(m.text)
                                        .padding(10)
                                        .background(m.role == .user ? Color.accentColor.opacity(0.25) : Color.secondary.opacity(0.15),
                                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .textSelection(.enabled)
                                    if m.role == .assistant { Spacer(minLength: 40) }
                                }
                                .id(i)
                            }
                            if session.history.messages.isEmpty {
                                Text("Hali suhbat yo'q. O'ng tugma → Gaplashish.").foregroundStyle(.secondary).padding()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onAppear { if let last = session.history.messages.indices.last { proxy.scrollTo(last) } }
                }
                HStack {
                    Button("Suhbatni tozalash") { session.history.clear() }
                    Spacer()
                    Text("\(session.history.messages.count) xabar").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(minWidth: 320)

            VStack(alignment: .leading, spacing: 8) {
                Text("\(petName) eslab qolganlari").font(.headline)
                List {
                    ForEach(memory.facts, id: \.self) { f in Text("• \(f)") }
                    if memory.facts.isEmpty { Text("Hali hech narsa.").foregroundStyle(.secondary) }
                }
                HStack {
                    Button { export() } label: { Label("Eksport", systemImage: "square.and.arrow.up") }
                    Button { importFacts() } label: { Label("Import", systemImage: "square.and.arrow.down") }
                    Spacer()
                    if let status { Text(status).font(.caption).foregroundStyle(.secondary) }
                }
            }
            .padding(12)
            .frame(minWidth: 260)
        }
        .frame(width: 720, height: 420)
    }

    private func export() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(petName.lowercased())-xotira.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let payload: [String: Any] = ["pet": petName, "exported": ISO8601DateFormatter().string(from: Date()),
                                      "facts": memory.facts, "history": session.history.messages.map { ["role": $0.role.rawValue, "text": $0.text] }]
        if let data = try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted]) {
            try? data.write(to: url)
            status = "Saqlandi"
        }
    }

    private func importFacts() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url,
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { status = "O'qib bo'lmadi"; return }
        let facts = (json["facts"] as? [String]) ?? (try? JSONDecoder().decode([String].self, from: data)) ?? []
        memory.add(facts)
        if let hist = json["history"] as? [[String: String]] {
            for m in hist { if let r = m["role"], let t = m["text"], let role = ChatMessage.Role(rawValue: r) { session.history.append(ChatMessage(role: role, text: t)) } }
        }
        status = "\(facts.count) ta fakt qo'shildi"
        onMemoryChanged()
    }
}

@MainActor
final class HistoryWindowController {
    private var window: NSWindow?
    func show(session: ChatSession, memory: MemoryStore, petName: String, onMemoryChanged: @escaping () -> Void) {
        if window == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: HistoryView(session: session, memory: memory, petName: petName, onMemoryChanged: onMemoryChanged)))
            w.title = "Suhbat va xotira"
            w.styleMask = [.titled, .closable, .resizable]
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}
