import AppKit
import SwiftUI

/// Non-activating floating panel that follows the pet and can take keyboard focus for chat.
final class BubblePanel: NSPanel {
    init(contentView: NSView) {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 320, height: 120),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .none
        self.contentView = contentView
    }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
