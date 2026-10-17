import Testing
import AppKit
@testable import Lobar

@MainActor
struct ContextMenuBuilderTests {
    func makeState() -> MenuState {
        MenuState(outfits: [("atlas", "Atlas"), ("adras", "Adras")], currentOutfit: "adras",
                  isSleeping: false, launchAtLogin: true, pomodoroRunning: false)
    }

    @Test func buildsUzbekItemsInOrder() {
        let menu = ContextMenuBuilder.build(state: makeState(), actions: MenuActions())
        let titles = menu.items.filter { !$0.isSeparatorItem }.map(\.title)
        #expect(titles == ["Gaplashish", "Uxla", "Boshini silash", "Kursor yoniga chaqirish",
                           "Kiyimlar", "Vazifalar", "Statistika", "O'ynaymizmi?", "Pomodoro boshlash", "Sozlamalar", "Mac bilan birga yoqish", "Yangilanishni tekshirish",
                           "Eslab qolganlari", "Xotirani tozalash", "Yashirish", "Chiqish"])
    }

    @Test func outfitSubmenuMarksCurrent() throws {
        let menu = ContextMenuBuilder.build(state: makeState(), actions: MenuActions())
        let kiyimlar = try #require(menu.items.first { $0.title == "Kiyimlar" }?.submenu)
        #expect(kiyimlar.items.map(\.title) == ["Atlas", "Adras"])
        #expect(kiyimlar.items[1].state == .on)
        #expect(kiyimlar.items[0].state == .off)
    }

    @Test func sleepingShowsWakeAndLoginCheckmark() {
        var s = makeState(); s.isSleeping = true; s.pomodoroRunning = true
        let menu = ContextMenuBuilder.build(state: s, actions: MenuActions())
        #expect(menu.items.contains { $0.title == "Uyg'ot" })
        #expect(menu.items.contains { $0.title == "Pomodoro to'xtatish" })
        #expect(menu.items.first { $0.title == "Mac bilan birga yoqish" }?.state == .on)
    }

    @Test func clickingItemInvokesAction() throws {
        var called = false
        var actions = MenuActions()
        actions.headPat = { called = true }
        let menu = ContextMenuBuilder.build(state: makeState(), actions: actions)
        let item = try #require(menu.items.first { $0.title == "Boshini silash" })
        _ = item.target?.perform(item.action, with: item)
        #expect(called)
    }
}
