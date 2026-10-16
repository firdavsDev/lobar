import AppKit

struct MenuState {
    var outfits: [(id: String, title: String)]
    var currentOutfit: String
    var isSleeping: Bool
    var launchAtLogin: Bool
    var pomodoroRunning: Bool
}

/// Closures wired by AppDelegate; nil closures still produce items (no-op) so the menu layout is stable.
struct MenuActions {
    var chat: () -> Void = {}
    var sleepToggle: () -> Void = {}
    var headPat: () -> Void = {}
    var comeToCursor: () -> Void = {}
    var setOutfit: (String) -> Void = { _ in }
    var tasks: () -> Void = {}
    var stats: () -> Void = {}
    var play: () -> Void = {}
    var pomodoroToggle: () -> Void = {}
    var settings: () -> Void = {}
    var launchAtLoginToggle: () -> Void = {}
    var checkUpdates: () -> Void = {}
    var showMemory: () -> Void = {}
    var clearMemory: () -> Void = {}
    var hide: () -> Void = {}
    var quit: () -> Void = {}
}

/// Target object that keeps closures alive and dispatches NSMenuItem actions.
@MainActor
final class MenuItemTarget: NSObject {
    private let handler: (String?) -> Void
    init(_ handler: @escaping (String?) -> Void) { self.handler = handler }
    @objc func fire(_ sender: NSMenuItem) { handler(sender.representedObject as? String) }
}

@MainActor
enum ContextMenuBuilder {
    static func build(state: MenuState, actions: MenuActions) -> NSMenu {
        let menu = NSMenu()
        var targets: [MenuItemTarget] = []

        func add(_ title: String, symbol: String, checked: Bool = false, represented: String? = nil,
                 _ handler: @escaping (String?) -> Void) -> NSMenuItem {
            let target = MenuItemTarget(handler)
            targets.append(target)
            let item = NSMenuItem(title: title, action: #selector(MenuItemTarget.fire(_:)), keyEquivalent: "")
            item.target = target
            item.representedObject = represented
            item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
            item.state = checked ? .on : .off
            menu.addItem(item)
            return item
        }

        _ = add("Gaplashish", symbol: "bubble.left.fill") { _ in actions.chat() }
        _ = add(state.isSleeping ? "Uyg'ot" : "Uxla", symbol: state.isSleeping ? "sun.max.fill" : "moon.zzz.fill") { _ in actions.sleepToggle() }
        _ = add("Boshini silash", symbol: "hand.raised.fill") { _ in actions.headPat() }
        _ = add("Kursor yoniga chaqirish", symbol: "cursorarrow.rays") { _ in actions.comeToCursor() }

        let outfitsItem = NSMenuItem(title: "Kiyimlar", action: nil, keyEquivalent: "")
        outfitsItem.image = NSImage(systemSymbolName: "tshirt.fill", accessibilityDescription: nil)
        let sub = NSMenu()
        for outfit in state.outfits {
            let target = MenuItemTarget { id in if let id { actions.setOutfit(id) } }
            targets.append(target)
            let item = NSMenuItem(title: outfit.title, action: #selector(MenuItemTarget.fire(_:)), keyEquivalent: "")
            item.target = target
            item.representedObject = outfit.id
            item.state = outfit.id == state.currentOutfit ? .on : .off
            sub.addItem(item)
        }
        outfitsItem.submenu = sub
        menu.addItem(outfitsItem)

        _ = add("Vazifalar", symbol: "checklist") { _ in actions.tasks() }
        _ = add("Statistika", symbol: "chart.bar.fill") { _ in actions.stats() }
        _ = add("O'ynaymizmi?", symbol: "gamecontroller.fill") { _ in actions.play() }
        _ = add(state.pomodoroRunning ? "Pomodoro to'xtatish" : "Pomodoro boshlash", symbol: "timer") { _ in actions.pomodoroToggle() }
        _ = add("Sozlamalar", symbol: "gearshape.fill") { _ in actions.settings() }
        _ = add("Mac bilan birga yoqish", symbol: "power", checked: state.launchAtLogin) { _ in actions.launchAtLoginToggle() }
        _ = add("Yangilanishni tekshirish", symbol: "arrow.down.circle") { _ in actions.checkUpdates() }
        menu.addItem(.separator())
        _ = add("Eslab qolganlari", symbol: "book.fill") { _ in actions.showMemory() }
        _ = add("Xotirani tozalash", symbol: "eraser.fill") { _ in actions.clearMemory() }
        menu.addItem(.separator())
        _ = add("Yashirish", symbol: "eye.slash.fill") { _ in actions.hide() }
        _ = add("Chiqish", symbol: "xmark.circle.fill") { _ in actions.quit() }

        // keep targets alive as long as the menu lives
        objc_setAssociatedObject(menu, &targetsKey, targets, .OBJC_ASSOCIATION_RETAIN)
        return menu
    }
}

nonisolated(unsafe) private var targetsKey: UInt8 = 0
