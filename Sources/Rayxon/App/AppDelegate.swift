import AppKit
import os

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var pet: PetController?
    private var statusItem: StatusItemController?
    private let surfaces = WindowSurfaceProvider()
    private var catalog: SpriteCatalog?
    private let settings = SettingsStore()
    private let memory = MemoryStore(fileURL: Paths.memoryFile)
    private var chat: ChatSession?
    private var bubble: BubbleController?
    private let settingsWindow = SettingsWindowController()
    private var voice: VoiceService?
    private var wellness: WellnessService?
    private let tasks = TaskStore(fileURL: Paths.tasksFile)
    private let tasksWindow = TasksWindowController()
    private let stats = StatsStore(fileURL: Paths.statsFile)
    private let statsWindow = StatsWindowController()
    private let historyWindow = HistoryWindowController()
    private var appWatcher = AppWatcher()
    private var appObserver: NSObjectProtocol?
    private let gitWatcher = GitWatcher()
    private var weatherTimer: Timer?
    private var lastWeather: Weather?
    private var bread: BreadDrop?
    private var cat: CatVisitor?
    private var catTimer: Timer?
    private var peers: PeerService?
    private var gameWins = 0, gameLosses = 0
    private let hotKey = HotKey()
    private var weatherEvents = WeatherEvents()
    private var floorProps: [FloorProp] = []
    private var birthdayShownDay: Int?
    private var activeTimer: Timer?
    private var mood = Mood()
    private var now: Double { Date().timeIntervalSince1970 }

    private func line(_ e: PhraseBook.Event, task: String = "") -> String {
        PhraseBook.line(for: e, tone: mood.tone, name: settings.displayName, task: task)
    }
    private func touch() { settings.lastInteraction = Date(); settings.affection = mood.affection }
    private var laughs = LaughLimiter()
    private var pendingWhileAsleep: [String] = []
    /// Everything she says goes through here. While asleep, lines are queued (max 3) and replayed on wake.
    private func sayAndSpeak(_ raw: String, seconds: Double? = nil, force: Bool = false) {
        let text = laughs.filter(raw)
        if let pet, pet.isSleeping, !force {
            if pendingWhileAsleep.count < 3 { pendingWhileAsleep.append(text) }
            return
        }
        bubble?.say(text, seconds: seconds); voice?.speak(text)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        mood = Mood(affection: settings.affection)
        mood.decay(hoursSinceLastInteraction: Date().timeIntervalSince(settings.lastInteraction) / 3600)
        do {
            let catalog = try SpriteCatalog()
            self.catalog = catalog
            let outfit = catalog.outfits.contains(settings.outfit) ? settings.outfit : (catalog.outfits.first ?? "atlas")
            let pet = PetController(catalog: catalog, outfit: outfit)
            self.pet = pet
            surfaces.onUpdate = { [weak pet] in pet?.supports = $0 }
            surfaces.isActive = { [weak pet] in guard let pet else { return false }; return !pet.isHidden && !pet.isSleeping }
            surfaces.start()

            pet.setScale(settings.petScale)
            let bubble = BubbleController(pet: pet)
            self.bubble = bubble
            applyBubbleSettings()
            let chat = ChatSession(memory: memory, providerFactory: { [settings] in settings.makeProvider() },
                                   userName: { [settings] in settings.userName })
            chat.petName = { [settings] in settings.displayName }
            chat.tone = { [weak self] in self?.mood.tone ?? .sassy }
            chat.relationship = { [settings] in settings.relationship }
            self.chat = chat
            bubble.onSend = { [weak self] text in self?.handleChat(text) }
            bubble.model.muted = !settings.voiceEnabled
            bubble.model.onToggleMute = { [weak self] in
                guard let self else { return }
                self.settings.voiceEnabled.toggle()
                self.bubble?.model.muted = !self.settings.voiceEnabled
                if !self.settings.voiceEnabled { self.voice?.stop() }
            }

            let voice = VoiceService(engine: EdgeTTSCLIEngine(),
                                     isEnabled: { [settings] in settings.voiceEnabled },
                                     voiceName: { [settings] in settings.voiceName },
                                     volume: { [settings] in settings.volume })
            voice.onSpeakingStart = { [weak pet] in pet?.setTalking(true) }
            voice.onSpeakingEnd = { [weak pet] in pet?.setTalking(false) }
            voice.onProblem = { [weak bubble] msg in bubble?.say(msg, seconds: 8) }
            self.voice = voice

            SoundFX.enabled = { [settings] in settings.sfxEnabled }
            SoundFX.volume = { [settings] in settings.volume }
            let wellness = WellnessService(settings: settings)
            wellness.tasks = tasks
            wellness.secondsIdle = { PetController.secondsSinceUserInput() }
            wellness.onRoutine = { [weak self] e in self?.handleRoutine(e) }
            wellness.onNight = { [weak self] night in
                guard let self, let pet = self.pet, self.settings.nightMode else { return }
                if night, !pet.isSleeping { self.autoSlept = true; pet.sleep(); self.sayAndSpeak(self.line(.night), force: true) }
                else if !night, pet.isSleeping, self.autoSlept { self.autoSlept = false; pet.wake() }
            }
            wellness.lineFor = { [weak self] ev in self?.line(ev) ?? "..." }
            wellness.onReminder = { [weak self] kind, line in
                guard let self, let pet = self.pet else { return }
                self.stats.record(kind == .water ? .water : (kind == .eyes ? .eyes : .posture))
                let state: PetState = kind == .water ? .drink : (kind == .eyes ? .eyes : .stretch)
                pet.react(state, seconds: 5)
                self.sayAndSpeak(line, seconds: 8)
            }
            wellness.onPomodoro = { [weak self] transition, line in
                guard let self, let pet = self.pet else { return }
                if transition == .breakStarted { self.stats.record(.pomodoro) }
                if pet.isSleeping { self.sayAndSpeak(line); return }
                if transition == .breakStarted { pet.react(.eat, seconds: 5) } else { pet.celebrate(seconds: 2) }
                self.sayAndSpeak(line, seconds: 8)
            }
            wellness.onTaskDue = { [weak self] task in
                guard let self, let pet = self.pet else { return }
                if !pet.isSleeping { pet.celebrate(seconds: 3) }
                self.sayAndSpeak(self.line(.taskDue, task: task.title), seconds: 15)
            }
            wellness.onChatter = { [weak self] in
                guard let self, let pet = self.pet, self.settings.chatterEnabled, !pet.isSleeping,
                      self.bubble?.isVisible != true else { return }
                let hour = Calendar.current.component(.hour, from: Date())
                var rng = SystemRandomNumberGenerator()
                let canned = PhraseBook.chatter(hour: hour, tone: self.mood.tone, openTasks: self.tasks.openCount,
                                                name: self.settings.displayName, relationship: self.settings.relationship, using: &rng)
                if self.mood.tone == .sulky { pet.react(.annoyed, seconds: 4) }
                guard self.settings.llmChatter, let chat = self.chat, self.settings.makeProvider() != nil else {
                    self.sayAndSpeak(canned, seconds: 7); return
                }
                let minutesQuiet = Int(Date().timeIntervalSince(self.settings.lastInteraction) / 60)
                let ctx = "Soat \(hour):\(String(format: "%02d", Calendar.current.component(.minute, from: Date()))). " +
                    "Foydalanuvchi \(minutesQuiet) daqiqadan beri sen bilan gaplashmagan. " +
                    "Ochiq vazifalar: \(self.tasks.openCount) ta\(self.tasks.tasks.first(where: { !$0.done }).map { " (masalan: \($0.title))" } ?? ""). " +
                    (self.wellness?.pomodoroStatus.map { "Pomodoro: \($0). " } ?? "") +
                    "Kayfiyating: \(self.mood.tone == .sulky ? "xafa" : (self.mood.tone == .sweet ? "xursand" : "injiq"))."
                Task {
                    let text = (try? await chat.unprompted(context: ctx)) ?? canned
                    self.sayAndSpeak(text, seconds: 8)
                }
            }
            tasks.onCompleted = { [weak self] _ in
                guard let self, let pet = self.pet else { return }
                self.stats.record(.taskDone); self.mood.taskDone(); self.touch()
                SoundFX.play(.done); pet.celebrate(seconds: 2)
                self.sayAndSpeak(self.line(self.tasks.openCount == 0 ? .allTasksDone : .taskDone), seconds: 6)
            }
            self.wellness = wellness
            pet.funEnabled = { [settings] in settings.funEvents }
            startAppReactions()
            startWeather()
            startGitWatcher()
            scheduleCat()
            startPeers()
            applyHotKey()
            // active-time meter: count a minute when the user touched input in the last 2 minutes
            let at = Timer(timeInterval: 60, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    if PetController.secondsSinceUserInput() < 120 { self.stats.addActive(seconds: 60) }
                }
            }
            RunLoop.main.add(at, forMode: .common)
            activeTimer = at

            pet.onRightClick = { [weak self] event, view in
                guard let self else { return }
                NSMenu.popUpContextMenu(self.buildMenu(), with: event, for: view)
            }
            pet.onEvent = { [weak self] event in self?.handle(event) }
            pet.onActivity = { [weak self] a in
                guard let self, let ev = PhraseBook.event(for: a), Int.random(in: 0..<3) == 0 else { return }
                self.bubble?.say(self.line(ev), seconds: 5)
            }
            statusItem = StatusItemController { [weak self] in self?.buildMenu() ?? NSMenu() }

            if let drop = ProcessInfo.processInfo.environment["RAYXON_DEBUG_DROP_Y"], let y = Double(drop) {
                pet.debugDrop(toY: y)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in self?.checkBirthday() }
            if let ev = ProcessInfo.processInfo.environment["RAYXON_DEBUG_EVENT"] {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    guard let self else { return }
                    switch ev {
                    case "rain": self.handleWeatherEvent(.rainStarted)
                    case "snow": self.handleWeatherEvent(.snowStarted)
                    case "birthday":
                        self.settings.birthdayEnabled = true; self.settings.birthday = Date(); self.birthdayShownDay = nil; self.checkBirthday()
                    default: break
                    }
                }
            }
            if let say = ProcessInfo.processInfo.environment["RAYXON_DEBUG_SAY"], !say.isEmpty {
                bubble.say(say); voice.speak(say, force: true)
            }
            if let shotDir = ProcessInfo.processInfo.environment["RAYXON_DEBUG_SHOT"] { debugShots(to: shotDir) }
            Log.app.info("Rayxon launched")
        } catch {
            Log.app.error("Failed to load sprites: \(error.localizedDescription)")
            NSApp.terminate(nil)
        }
    }

    // MARK: - Pet events → bubble lines

    private func handle(_ event: PetController.Event) {
        guard let pet, let bubble else { return }
        switch event {
        case .cursorNear:
            if !bubble.isVisible, Int.random(in: 0..<2) == 0 { bubble.say(line(.cursorNear), seconds: 3) }
        case .doubleClicked:
            dropBread()
        case .peekaboo:
            SoundFX.play(.happy); sayAndSpeak(line(.peekaboo), seconds: 4)
        case .chaseFailed:
            sayAndSpeak(line(.chaseFail), seconds: 5)
        case .chaseCaught:
            SoundFX.play(.happy); bubble.say("Ushladim! Hihi.", seconds: 3); mood.chatted()
        case .parachuteOpened:
            sayAndSpeak(line(.parachute), seconds: 5)
        case .dragStarted:
            SoundFX.play(.pick)
            touch()
            if !bubble.model.showInput, Int.random(in: 0..<2) == 0 { sayAndSpeak(line(Bool.random() ? .drag : .dragArmsOut)) }
        case .clicked:
            touch()
            if mood.clicked(at: now) {
                pet.react(.annoyed, seconds: 3)
                sayAndSpeak(line(.clickSpam))
            }
        case .dizzy:
            SoundFX.play(.dizzy)
            pet.triggerDizzy()
            mood.shaken(at: now); touch()
            sayAndSpeak(line(.dizzy))
            let fact = "Foydalanuvchi meni silkitishni yoqtiradi (boshim aylangan)"
            if !memory.contains(fact) { memory.add([fact]) }
        case .fellAndLanded:
            SoundFX.play(.land)
            sayAndSpeak(line(.fell))
        case .hardLanding:
            SoundFX.play(.dizzy)
            mood.shaken(at: now); touch()
            sayAndSpeak(line(.hardLanding))
        case .headPat:
            touch()
            switch mood.headPat(at: now) {
            case .pleased: SoundFX.play(.happy); sayAndSpeak(line(.headPat))
            case .annoyed: SoundFX.play(.annoyed); pet.react(.annoyed, seconds: 3); sayAndSpeak(line(.headPatTooMuch))
            }
            touch()
        case .slept:
            SoundFX.play(.sleep)
            wellness?.setPetSleeping(true)
            bubble.hide()
            sayAndSpeak(line(.sleep), seconds: 4, force: true)
        case .woke:
            SoundFX.play(.wake)
            wellness?.setPetSleeping(false)
            bubble.say(line(.wake))
            let queued = pendingWhileAsleep; pendingWhileAsleep.removeAll()
            for (i, text) in queued.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + 4 + Double(i) * 7) { [weak self] in self?.sayAndSpeak(text, seconds: 8) }
            }
        case .arrivedAtCursor:
            sayAndSpeak(line(.cameToCursor))
        }
    }

    // MARK: - Chat

    private func openChat() {
        guard let pet, let bubble else { return }
        if pet.isSleeping { pet.wake() }
        touch()
        bubble.openChat(greeting: settings.makeProvider() == nil ? line(.noKey) : line(.chatOpen))
    }

    private func handleChat(_ text: String) {
        guard let chat, let bubble, let pet, !bubble.model.isBusy else { return }
        bubble.showTyping()
        Task {
            do {
                let reply = laughs.filter(try await chat.send(text))
                mood.chatted(); touch(); stats.record(.chat)
                bubble.finishReply(reply)
                if settings.voiceEnabled {
                    voice?.speak(reply)
                } else {
                    pet.setTalking(true)
                    try? await Task.sleep(for: .seconds(min(6, 1 + Double(reply.count) * 0.05)))
                    pet.setTalking(false)
                }
            } catch let e as LLMError {
                bubble.finishReply(e.userMessage)
            } catch {
                bubble.finishReply("Xato: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Menu

    private func buildMenu() -> NSMenu {
        guard let pet, let catalog else { return NSMenu() }
        let state = MenuState(
            outfits: catalog.outfits.map { ($0, catalog.title(for: $0)) },
            currentOutfit: pet.outfit,
            isSleeping: pet.isSleeping,
            launchAtLogin: LaunchAtLogin.isEnabled,
            pomodoroRunning: wellness?.pomodoro.isRunning ?? false)
        var actions = MenuActions()
        actions.chat = { [weak self] in self?.openChat() }
        actions.sleepToggle = { [weak self] in
            guard let self, let pet = self.pet else { return }
            pet.isSleeping ? pet.wake() : pet.sleep()
            self.wellness?.setPetSleeping(pet.isSleeping)
        }
        actions.headPat = { [weak pet] in pet?.headPat() }
        actions.tasks = { [weak self] in
            guard let self else { return }
            self.tasksWindow.show(store: self.tasks, petName: self.settings.displayName, onAdded: { [weak self] in
                guard let self else { return }
                self.sayAndSpeak(self.line(.taskAdded))
            })
        }
        actions.play = { [weak self] in self?.offerGames() }
        actions.stats = { [weak self] in
            guard let self else { return }
            self.statsWindow.show(stats: self.stats, petName: self.settings.displayName)
        }
        actions.checkUpdates = { [weak self] in
            guard let self else { return }
            self.bubble?.say("Tekshiryapman…", seconds: 3)
            Task {
                do {
                    if let r = try await UpdateChecker.check() {
                        self.bubble?.say("Yangi versiya bor: \(r.version). Yuklab olaman?", seconds: 10)
                        NSWorkspace.shared.open(r.pageURL)
                    } else {
                        self.bubble?.say("Eng yangi versiya sizda (\(UpdateChecker.currentVersion)).", seconds: 5)
                    }
                } catch {
                    self.bubble?.say("Tekshira olmadim. Keyinroq urinib ko'ring.", seconds: 5)
                }
            }
        }
        actions.launchAtLoginToggle = { [weak self] in
            guard let self else { return }
            if let msg = LaunchAtLogin.toggle() { self.bubble?.say(msg, seconds: 8) }
            else { self.bubble?.say(LaunchAtLogin.isEnabled ? "Endi Mac bilan birga uyg'onaman." : "Avtostart o'chirildi.", seconds: 4) }
        }
        actions.pomodoroToggle = { [weak self] in self?.wellness?.togglePomodoro() }
        actions.comeToCursor = { [weak pet] in pet?.comeToCursor() }
        actions.setOutfit = { [weak self] id in
            guard let self, let pet = self.pet else { return }
            pet.setOutfit(id)
            self.settings.outfit = id
            pet.celebrate()
            self.sayAndSpeak(self.line(.outfit))
        }
        actions.settings = { [weak self] in
            guard let self else { return }
            self.settingsWindow.show(settings: self.settings, voices: [
                ("uz-UZ-MadinaNeural", "Madina (ayol)"), ("uz-UZ-SardorNeural", "Sardor (erkak)")],
                onTestVoice: { [weak self] in
                    guard let self else { return }
                    self.voice?.speak("Salom! Men \(self.settings.displayName)man. Ishlar qalay?", force: true)
                },
                onChange: { [weak self] in self?.applyBubbleSettings() })
        }
        actions.showMemory = { [weak self] in
            guard let self, let chat = self.chat else { return }
            self.historyWindow.show(session: chat, memory: self.memory, petName: self.settings.displayName, onMemoryChanged: {})
        }
        actions.clearMemory = { [weak self] in
            guard let self else { return }
            let alert = NSAlert()
            alert.messageText = "Xotirani tozalaymi?"
            alert.informativeText = "Rayxon siz haqingizda eslab qolgan hamma narsani unutadi."
            alert.addButton(withTitle: "Tozalash")
            alert.addButton(withTitle: "Bekor qilish")
            NSApp.activate()
            if alert.runModal() == .alertFirstButtonReturn {
                self.memory.clear()
                self.chat?.history.clear()
                self.bubble?.say(self.line(.memoryCleared))
            }
        }
        actions.hide = { [weak pet] in pet?.hide() }
        actions.quit = { NSApp.terminate(nil) }
        let menu = ContextMenuBuilder.build(state: state, actions: actions)
        if let status = wellness?.pomodoroStatus, let item = menu.items.first(where: { $0.title.hasPrefix("Pomodoro") }) {
            item.title = "Pomodoro to'xtatish (\(status))"
        }
        if pet.isHidden {
            let show = NSMenuItem(title: "Ko'rsatish", action: #selector(showPet), keyEquivalent: "")
            show.target = self
            show.image = NSImage(systemSymbolName: "eye.fill", accessibilityDescription: nil)
            menu.insertItem(show, at: 0)
        }
        return menu
    }

    @objc private func showPet() { pet?.show() }

    // MARK: - Fun: bread, cat, games, peers

    private func dropBread() {
        guard settings.funEvents, let pet, bread == nil, let screen = pet.currentScreen else { return }
        let x = pet.body.x + Double.random(in: -160...160)
        let clampedX = min(max(x, Double(screen.visibleFrame.minX) + 40), Double(screen.visibleFrame.maxX) - 40)
        pet.fetch(x: clampedX)
        bread = BreadDrop(x: clampedX, screen: screen, petX: { [weak pet] in pet?.body.x ?? 0 }, catchY: { [weak pet] in pet?.headY ?? 0 }) { [weak self] in
            guard let self, let pet = self.pet else { return }
            self.bread = nil
            let caught = abs(pet.body.x - clampedX) < 40
            if caught {
                SoundFX.play(.happy); pet.react(.eat, seconds: 5); self.mood.chatted(); self.touch()
                self.sayAndSpeak(self.line(.bread), seconds: 6)
            } else {
                pet.react(.annoyed, seconds: 3)
                self.bubble?.say("Non yerga tushdi... Isrof! Sizning aybingiz.", seconds: 5)
            }
        }
    }

    private func scheduleCat() {
        catTimer?.invalidate()
        let t = Timer(timeInterval: Double.random(in: 40...90) * 60, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.catVisit(); self?.scheduleCat() }
        }
        RunLoop.main.add(t, forMode: .common)
        catTimer = t
    }

    private func catVisit() {
        guard settings.funEvents, let pet, !pet.isSleeping, cat == nil, pet.support == .floor, let screen = pet.currentScreen else { return }
        cat = CatVisitor(screen: screen, petX: pet.body.x, onArrive: { [weak self] in
            guard let self, let pet = self.pet else { return }
            pet.celebrate(seconds: 5); self.sayAndSpeak(self.line(.catVisit), seconds: 6)
        }, onLeave: { [weak self] in self?.cat = nil })
    }

    private func offerGames() {
        guard let bubble, let pet else { return }
        if pet.isSleeping { pet.wake() }
        touch()
        bubble.ask("O'ynaymizmi? Qaysi o'yin?", choices: [("rps", "Tosh-qaychi-qog'oz"), ("hand", "Qaysi qo'limda?")]) { [weak self] id in
            if id == "rps" { self?.playRPS() } else { self?.playHand() }
        }
    }

    private func playRPS() {
        guard let bubble, let pet else { return }
        bubble.ask("Tanlang!", choices: Games.RPS.allCases.map { ($0.rawValue, "\($0.emoji) \($0.rawValue)") }) { [weak self] id in
            guard let self, let user = Games.RPS(rawValue: id) else { return }
            var rng = SystemRandomNumberGenerator()
            let mine = Games.randomRPS(using: &rng)
            switch Games.rps(user: user, pet: mine) {
            case .userWins:
                self.gameWins += 1; pet.react(.annoyed, seconds: 3); SoundFX.play(.annoyed); self.mood.chatted()
                self.sayAndSpeak("Men \(mine.rawValue.lowercased()) oldim... Yutdingiz. Baxtli odam. \(self.gameWins):\(self.gameLosses)", seconds: 6)
            case .petWins:
                self.gameLosses += 1; pet.celebrate(seconds: 3); SoundFX.play(.happy)
                self.sayAndSpeak("Men \(mine.rawValue.lowercased())! Yutdim! Hihi. \(self.gameWins):\(self.gameLosses)", seconds: 6)
            case .draw:
                self.sayAndSpeak("Ikkimiz ham \(mine.rawValue.lowercased()). Durang. Yana?", seconds: 5)
            }
            self.stats.record(.chat)
        }
    }

    private func playHand() {
        guard let bubble, let pet else { return }
        var rng = SystemRandomNumberGenerator()
        let hidden = Games.hideHand(using: &rng)
        pet.react(.happy, seconds: 10)
        bubble.ask("Qo'limda non bor. Qaysi qo'limda?", choices: [("left", "Chap"), ("right", "O'ng")]) { [weak self] id in
            guard let self else { return }
            let guess: Games.Hand = id == "left" ? .left : .right
            if guess == hidden {
                self.gameWins += 1; SoundFX.play(.happy); pet.react(.eat, seconds: 4); self.mood.chatted()
                self.sayAndSpeak("To'g'ri! Mana, oling... yo'q, o'zim yeyman. Hihi.", seconds: 6)
            } else {
                self.gameLosses += 1; SoundFX.play(.annoyed); pet.celebrate(seconds: 3)
                self.sayAndSpeak("Noto'g'ri! \(hidden == .left ? "Chap" : "O'ng") qo'limda edi. Non meniki.", seconds: 6)
            }
        }
    }

    private func startPeers() {
        guard settings.lanPeers else { return }
        let p = PeerService(name: { [settings] in settings.displayName })
        p.onPeerHello = { [weak self] from, text in
            guard let self, let pet = self.pet, !pet.isSleeping else { return }
            pet.celebrate(seconds: 3)
            self.sayAndSpeak(self.line(.peerHello) + " (\(from): \"\(text)\")", seconds: 9)
        }
        p.start()
        peers = p
    }

    // MARK: - App reactions, weather, git

    private func startAppReactions() {
        appObserver = NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] n in
            // extract what we need before hopping to the main actor (Notification is not Sendable)
            let app = n.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            let bid = app?.bundleIdentifier
            let isSelf = app?.processIdentifier == ProcessInfo.processInfo.processIdentifier
            MainActor.assumeIsolated {
                guard let self, self.settings.appReactions, let pet = self.pet, !pet.isSleeping, let bid, !isSelf else { return }
                self.handleAppEvent(self.appWatcher.update(category: AppWatcher.category(for: bid), at: self.now))
            }
        }
        // distraction timer: re-evaluate the current app every 30s
        let t = Timer(timeInterval: 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, self.settings.appReactions, let bid = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return }
                self.handleAppEvent(self.appWatcher.update(category: AppWatcher.category(for: bid), at: self.now))
            }
        }
        RunLoop.main.add(t, forMode: .common)
        weatherTimer = t
    }

    private func handleAppEvent(_ e: AppWatcher.Event?) {
        guard let e, let pet, !pet.isSleeping, bubble?.isVisible != true else { return }
        switch e {
        case .distracted: pet.react(.annoyed, seconds: 4); sayAndSpeak(line(.distracted), seconds: 7); mood.reminderIgnored()
        case .backToWork: pet.celebrate(seconds: 2); bubble?.say(line(.backToWork), seconds: 5)
        case .startedCoding: if Int.random(in: 0..<3) == 0 { bubble?.say(line(.startedCoding), seconds: 5) }
        case .openedMessaging: if Int.random(in: 0..<3) == 0 { pet.react(.annoyed, seconds: 3); bubble?.say(line(.openedMessaging), seconds: 5) }
        }
    }

    private func startWeather() {
        weatherTick()
        let t = Timer(timeInterval: 2 * 3600, repeats: true) { [weak self] _ in MainActor.assumeIsolated { self?.weatherTick() } }
        RunLoop.main.add(t, forMode: .common)
    }

    private func weatherTick() {
            guard settings.weatherEnabled else { return }
            Task { [weak self] in
                guard let self, let w = try? await Weather.fetch() else { return }
                let first = self.lastWeather == nil
                self.lastWeather = w
                self.handleWeatherEvent(self.weatherEvents.update(w))
                if first, let pet = self.pet, !pet.isSleeping {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in self?.sayAndSpeak(w.summaryUz, seconds: 9) }
                }
                if self.settings.weatherOutfit, let pet = self.pet, let catalog = self.catalog,
                   let o = Weather.suggestedOutfit(temperature: w.temperature, available: catalog.outfits), o != pet.outfit {
                    pet.setOutfit(o); self.settings.outfit = o
                }
            }
    }

    private func handleWeatherEvent(_ e: WeatherEvents.Event?) {
        guard let e, let pet, settings.funEvents else { return }
        switch e {
        case .rainStarted:
            pet.setHandProp("umbrella"); sayAndSpeak(line(.rain), seconds: 8)
        case .rainStopped:
            pet.setHandProp(nil); bubble?.say(line(.rainStopped), seconds: 5)
        case .snowStarted:
            pet.setHandProp(nil)
            if let screen = pet.currentScreen, let img = Props.image("snowman") {
                let x = pet.body.x + (pet.body.x > Double(screen.visibleFrame.midX) ? -110 : 110)
                let prop = FloorProp(image: img, x: x, screen: screen, height: 90, seconds: 20 * 60) { [weak self] in self?.floorProps.removeAll() }
                floorProps.append(prop)
            }
            pet.celebrate(seconds: 3); sayAndSpeak(line(.snow), seconds: 8)
        case .snowStopped:
            floorProps.forEach { $0.dismiss() }; floorProps.removeAll()
        }
    }

    /// Birthday: cake + gift on the floor, celebration, once per day.
    private func checkBirthday() {
        guard settings.birthdayEnabled, let bday = settings.birthday, Birthday.isToday(birthday: bday),
              let pet, let screen = pet.currentScreen else { return }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        guard birthdayShownDay != day else { return }
        birthdayShownDay = day
        if let cake = Props.image("cake") {
            floorProps.append(FloorProp(image: cake, x: pet.body.x - 90, screen: screen, height: 70, seconds: 3 * 3600) {})
        }
        if let gift = Props.image("gift") {
            floorProps.append(FloorProp(image: gift, x: pet.body.x + 90, screen: screen, height: 60, seconds: 3 * 3600) {})
        }
        SoundFX.play(.done); pet.celebrate(seconds: 6); mood.chatted(); mood.chatted()
        let age = Birthday.age(birthday: bday)
        sayAndSpeak(line(.birthday) + (age > 0 && age < 120 ? " \(age) yosh — hali yosh!" : ""), seconds: 12, force: true)
    }

    private func applyHotKey() {
        hotKey.unregister()
        guard settings.hotkeyEnabled else { return }
        // ⌥Space (kVK_Space = 49)
        hotKey.register(keyCode: 49, modifiers: HotKey.carbonModifiers(option: true, command: false, control: false, shift: false)) { [weak self] in
            guard let self, let bubble = self.bubble else { return }
            if bubble.isVisible, bubble.model.showInput { bubble.hide() } else { self.openChat() }
        }
    }

    private func startGitWatcher() {
        gitWatcher.onCommit = { [weak self] repo in
            guard let self, let pet = self.pet, !pet.isSleeping else { return }
            SoundFX.play(.done); pet.celebrate(seconds: 3); self.mood.taskDone()
            self.sayAndSpeak(self.line(.commit) + " (\(repo))", seconds: 7)
        }
        restartGitWatcher()
    }

    private func restartGitWatcher() {
        let path = (settings.projectsFolder as NSString).expandingTildeInPath
        var isDir: ObjCBool = false
        if !path.isEmpty, FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
            gitWatcher.start(root: URL(fileURLWithPath: path))
        } else { gitWatcher.stop() }
    }

    private var autoSlept = false
    private func handleRoutine(_ e: RoutineEngine.Event) {
        guard let pet else { return }
        switch e {
        case .morning:
            checkBirthday()
            if !pet.isSleeping {
                sayAndSpeak(line(.morning), seconds: 8); pet.celebrate(seconds: 2)
                DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
                    guard let self else { return }
                    self.pet?.react(.read, seconds: 6)
                    self.sayAndSpeak("Bugungi maqol: " + Proverbs.proverb(for: Date()), seconds: 12)
                }
            }
        case .lunch: if !pet.isSleeping { pet.react(.dastarxon, seconds: 6); sayAndSpeak(line(.lunch), seconds: 8) }
        case .evening:
            if !pet.isSleeping {
                pet.react(.stretch, seconds: 4); sayAndSpeak(line(.evening), seconds: 8)
                DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
                    guard let self else { return }
                    self.pet?.celebrate(seconds: 4)
                    self.sayAndSpeak(Proverbs.joke(for: Date()), seconds: 14)
                }
            }
        case .userAway: if !pet.isSleeping { bubble?.say(line(.userAway), seconds: 6) }
        case .userGone: if !pet.isSleeping { autoSlept = true; pet.sleep(); sayAndSpeak(line(.userGone), seconds: 6, force: true) }
        case .userBack:
            if pet.isSleeping, autoSlept { autoSlept = false; pet.wake() }
            sayAndSpeak(line(.userBack), seconds: 6)
        }
    }

    /// Debug: open settings + tasks windows, snapshot their content views to PNG, quit.
    private func debugShots(to dir: String) {
        settingsWindow.show(settings: settings, voices: [("uz-UZ-MadinaNeural", "Madina (ayol)"), ("uz-UZ-SardorNeural", "Sardor (erkak)")],
                            onTestVoice: {}, onChange: {})
        tasks.add("Suv ichish"); tasks.add("README yozish", dueAt: Date().addingTimeInterval(3600))
        tasksWindow.show(store: tasks, petName: settings.displayName, onAdded: {})
        func snap(_ w: NSWindow?, _ name: String) {
            guard let w, let v = w.contentView else { return }
            let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).png")
            w.effectiveAppearance.performAsCurrentDrawingAppearance {
                guard let rep = v.bitmapImageRepForCachingDisplay(in: v.bounds) else { return }
                v.cacheDisplay(in: v.bounds, to: rep)
                let size = v.bounds.size
                let img = NSImage(size: size)
                img.lockFocus()
                (w.backgroundColor ?? NSColor.windowBackgroundColor).setFill()
                NSRect(origin: .zero, size: size).fill()
                rep.draw(in: NSRect(origin: .zero, size: size))
                img.unlockFocus()
                if let tiff = img.tiffRepresentation, let out = NSBitmapImageRep(data: tiff),
                   let png = out.representation(using: .png, properties: [:]) { try? png.write(to: url) }
            }
        }
        let panes = SettingsPane.allCases
        for (i, pane) in panes.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + Double(i) * 0.8) {
                self.settingsWindow.debugSelect(pane)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { snap(self.settingsWindow.debugWindow, "settings-\(pane.rawValue)") }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 + Double(panes.count) * 0.8 + 0.8) {
            snap(self.tasksWindow.debugWindow, "tasks")
            NSApp.terminate(nil)
        }
    }

    /// Re-applies settings that affect live UI (called when the settings window closes or on a timer).
    private func applyBubbleSettings() {
        bubble?.model.name = settings.displayName
        bubble?.model.muted = !settings.voiceEnabled
        bubble?.model.width = settings.bubbleWidth
        bubble?.model.fontSize = settings.bubbleFontSize
        if let pet, abs(pet.scale - settings.petScale) > 0.001 { pet.setScale(settings.petScale) }
        wellness?.reconfigure()
        restartGitWatcher()
        applyHotKey()
    }
}
