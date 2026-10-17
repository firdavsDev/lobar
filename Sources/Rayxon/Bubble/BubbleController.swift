import AppKit
import SwiftUI

/// Shows speech bubbles above the pet; plain bubbles auto-dismiss, chat bubbles stay until closed.
@MainActor
final class BubbleController {
    let model = BubbleModel()
    private let panel: BubblePanel
    private let host: NSHostingView<BubbleView>
    private weak var pet: PetController?
    private var dismissTimer: Timer?
    private var followTimer: Timer?
    private var previousApp: NSRunningApplication?
    var onSend: ((String) -> Void)?

    init(pet: PetController) {
        self.pet = pet
        let m = model
        var sendRef: ((String) -> Void)?
        var closeRef: (() -> Void)?
        host = NSHostingView(rootView: BubbleView(model: m, onSend: { sendRef?($0) }, onClose: { closeRef?() }))
        panel = BubblePanel(contentView: host)
        sendRef = { [weak self] text in self?.onSend?(text) }
        closeRef = { [weak self] in self?.hide() }
        pet.window.addChildWindow(panel, ordered: .above)
        let t = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.reposition() }
        }
        RunLoop.main.add(t, forMode: .common)
        followTimer = t
    }

    var isVisible: Bool { panel.isVisible }

    /// Bubble with choice buttons; stays until a choice is made or closed.
    func ask(_ text: String, choices: [(id: String, title: String)], onChoice: @escaping (String) -> Void) {
        dismissTimer?.invalidate()
        model.isTyping = false
        model.text = text
        model.choices = choices
        model.onChoice = { [weak self] id in
            self?.model.choices = []
            onChoice(id)
        }
        present()
    }

    /// Plain bubble: text only, auto-dismiss.
    func say(_ text: String, seconds: Double? = nil) {
        model.isTyping = false
        model.choices = []
        model.text = text
        if !model.showInput {
            dismissTimer?.invalidate()
            let dur = seconds ?? max(3, 0.06 * Double(text.count))
            dismissTimer = Timer.scheduledTimer(withTimeInterval: dur, repeats: false) { [weak self] _ in
                MainActor.assumeIsolated { self?.hide() }
            }
        }
        present()
    }

    func showTyping() {
        model.isTyping = true
        model.isBusy = true
        dismissTimer?.invalidate()
        present()
    }

    func openChat(greeting: String) {
        dismissTimer?.invalidate()
        model.showInput = true
        model.isTyping = false
        model.isBusy = false
        model.text = greeting
        if previousApp == nil, let front = NSWorkspace.shared.frontmostApplication, front != .current {
            previousApp = front
        }
        present()
        NSApp.activate()
        panel.makeKey()
    }

    func finishReply(_ text: String) {
        model.isTyping = false
        model.isBusy = false
        model.text = text
        if !model.showInput { say(text) }
        else { panel.makeKey() }
    }

    func hide() {
        dismissTimer?.invalidate()
        model.choices = []
        let wasChat = model.showInput
        model.showInput = false
        model.isTyping = false
        model.isBusy = false
        panel.orderOut(nil)
        if wasChat {
            if let app = previousApp, app != NSRunningApplication.current { app.activate() }
            previousApp = nil
        }
    }

    private func present() {
        host.layoutSubtreeIfNeeded()
        let size = host.fittingSize
        panel.setContentSize(size)
        reposition()
        panel.orderFront(nil)
    }

    private func reposition() {
        guard panel.isVisible, let pet else { return }
        let petFrame = pet.spriteFrame
        let size = panel.frame.size
        var x = petFrame.midX - size.width / 2
        var y = petFrame.maxY - 18
        if let screen = pet.window.screen ?? NSScreen.main {
            let vf = screen.visibleFrame
            x = min(max(x, vf.minX + 4), vf.maxX - size.width - 4)
            if y + size.height > vf.maxY { y = petFrame.minY - size.height - 4 }
        }
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
