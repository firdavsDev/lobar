import AppKit

/// Menu bar item that mirrors the context menu and offers Ko'rsatish when the pet is hidden.
@MainActor
final class StatusItemController {
    private let item: NSStatusItem
    private let menuProvider: () -> NSMenu

    init(menuProvider: @escaping () -> NSMenu) {
        self.menuProvider = menuProvider
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "face.smiling.inverse", accessibilityDescription: "Rayxon")
        item.button?.target = self
        item.button?.action = #selector(clicked)
    }

    @objc private func clicked() {
        let menu = menuProvider()
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }
}
