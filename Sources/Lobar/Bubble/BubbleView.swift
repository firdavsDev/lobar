import SwiftUI

struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX - 10, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.midX + 10, y: rect.minY))
        p.closeSubpath()
        return p
    }
}

@MainActor
@Observable
final class BubbleModel {
    var text: String = ""
    var name: String = "Lobar"
    var width: Double = 240
    var fontSize: Double = 13
    var isTyping = false
    var muted = false
    var onToggleMute: (() -> Void)?
    var choices: [(id: String, title: String)] = []
    var onChoice: ((String) -> Void)?
    var showInput = false
    var draft = ""
    var isBusy = false
}

struct BubbleView: View {
    @Bindable var model: BubbleModel
    var onSend: (String) -> Void
    var onClose: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button { model.onToggleMute?() } label: {
                        Image(systemName: model.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.caption).foregroundStyle(model.muted ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(model.muted ? "Ovozni yoqish" : "Ovozni o'chirish")
                    Text(model.name).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button(action: onClose) { Image(systemName: "xmark").font(.caption2) }
                        .buttonStyle(.plain).foregroundStyle(.secondary)
                }
                if model.isTyping {
                    Text("…yozyapti").font(.system(size: model.fontSize)).foregroundStyle(.secondary)
                } else {
                    Text(model.text).font(.system(size: model.fontSize)).fixedSize(horizontal: false, vertical: true)
                }
                if !model.choices.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(model.choices, id: \.id) { c in
                            Button(c.title) { model.onChoice?(c.id) }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        }
                    }
                }
                if model.showInput {
                    HStack(spacing: 6) {
                        TextField("Savol yozing, Enter bosing", text: $model.draft)
                            .textFieldStyle(.roundedBorder)
                            .focused($focused)
                            .onSubmit(send)
                            .disabled(model.isBusy)
                        Button(action: send) {
                            Image(systemName: "paperplane.fill").foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Color(red: 0.36, green: 0.58, blue: 0.28), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .disabled(model.isBusy || model.draft.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .padding(12)
            .frame(width: model.width, alignment: .leading)
            .background(Color(nsColor: NSColor(name: nil) { a in
                a.bestMatch(from: [.darkAqua]) == .darkAqua ? NSColor(white: 0.17, alpha: 0.97) : NSColor(red: 0.95, green: 0.97, blue: 0.90, alpha: 0.97)
            }), in: RoundedRectangle(cornerRadius: 14))
            BubbleTail().fill(Color(nsColor: NSColor(name: nil) { a in
                a.bestMatch(from: [.darkAqua]) == .darkAqua ? NSColor(white: 0.17, alpha: 0.97) : NSColor(red: 0.95, green: 0.97, blue: 0.90, alpha: 0.97)
            })).frame(width: 24, height: 10)
        }
        .onChange(of: model.showInput) { _, show in if show { focused = true } }
        .onAppear { if model.showInput { focused = true } }
    }

    private func send() {
        let t = model.draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        model.draft = ""
        onSend(t)
    }
}
