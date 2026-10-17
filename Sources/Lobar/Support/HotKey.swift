import Carbon
import AppKit

/// Global hotkey via Carbon RegisterEventHotKey — works without Accessibility permission.
@MainActor
final class HotKey {
    private var ref: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var callback: (() -> Void)?
    private static var instances: [UInt32: HotKey] = [:]
    private static var nextID: UInt32 = 1
    private let id: UInt32

    nonisolated static func carbonModifiers(option: Bool, command: Bool, control: Bool, shift: Bool) -> UInt32 {
        var m: UInt32 = 0
        if option { m |= UInt32(optionKey) }
        if command { m |= UInt32(cmdKey) }
        if control { m |= UInt32(controlKey) }
        if shift { m |= UInt32(shiftKey) }
        return m
    }

    init() { id = Self.nextID; Self.nextID += 1 }

    func register(keyCode: UInt32, modifiers: UInt32, _ action: @escaping () -> Void) {
        unregister()
        callback = action
        Self.instances[id] = self
        var hotKeyID = EventHotKeyID(signature: OSType(0x5258_4E48) /* 'RXNH' */, id: id)
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        if handler == nil {
            InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
                var hk = EventHotKeyID()
                GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                                  MemoryLayout<EventHotKeyID>.size, nil, &hk)
                let id = hk.id
                Task { @MainActor in HotKey.instances[id]?.callback?() }
                return noErr
            }, 1, &spec, nil, &handler)
        }
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &ref)
    }

    func unregister() {
        if let ref { UnregisterEventHotKey(ref); self.ref = nil }
        Self.instances[id] = nil
    }
}
