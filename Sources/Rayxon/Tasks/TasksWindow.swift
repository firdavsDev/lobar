import SwiftUI
import AppKit

struct TasksView: View {
    var store: TaskStore
    var petName: String
    var onAdded: (() -> Void)? = nil
    @State private var draft = ""
    @State private var withDue = false
    @State private var due = Date().addingTimeInterval(3600)
    private static let fmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "d MMM HH:mm"; return f }()

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                TextField("Yangi vazifa…", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(add)
                Button("Qo'shish", action: add).disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            HStack {
                Toggle("Eslatma vaqti", isOn: $withDue)
                if withDue {
                    DatePicker("", selection: $due, displayedComponents: [.date, .hourAndMinute]).labelsHidden()
                }
                Spacer()
            }
            List {
                ForEach(store.tasks) { task in
                    HStack {
                        Button { store.toggle(task.id) } label: {
                            Image(systemName: task.done ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.done ? .green : .secondary)
                        }.buttonStyle(.plain)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title).strikethrough(task.done).foregroundStyle(task.done ? .secondary : .primary)
                            if let d = task.dueAt {
                                Label(Self.fmt.string(from: d), systemImage: "bell").font(.caption)
                                    .foregroundStyle(d < Date() && !task.done ? .red : .secondary)
                            }
                        }
                        Spacer()
                        Button { store.remove(task.id) } label: { Image(systemName: "trash") }
                            .buttonStyle(.plain).foregroundStyle(.secondary)
                    }
                }
            }
            HStack {
                Text(store.tasks.isEmpty ? "\(petName): Vazifa yo'q. Dam olyapsizmi?" : "\(store.openCount) ta ochiq")
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Bajarilganlarni tozalash") { store.clearDone() }
                    .disabled(!store.tasks.contains(where: \.done))
            }
        }
        .padding()
        .frame(width: 380, height: 360)
    }

    private func add() {
        store.add(draft, dueAt: withDue ? due : nil)
        draft = ""
        onAdded?()
    }
}

@MainActor
final class TasksWindowController {
    private var window: NSWindow?
    var debugWindow: NSWindow? { window }

    func show(store: TaskStore, petName: String, onAdded: @escaping () -> Void) {
        if window == nil {
            let host = NSHostingController(rootView: TasksView(store: store, petName: petName, onAdded: onAdded))
            let w = NSWindow(contentViewController: host)
            w.title = "Vazifalar"
            w.styleMask = [.titled, .closable, .resizable]
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
    }
}
