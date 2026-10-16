import AppKit

/// Drives reminders + pomodoro on a 1 Hz timer; pauses when the screen locks or sleeps.
@MainActor
final class WellnessService {
    private var scheduler = ReminderScheduler()
    private(set) var pomodoro: PomodoroEngine
    private var timer: Timer?
    private let settings: SettingsStore
    var onReminder: ((ReminderKind, String) -> Void)?
    var onPomodoro: ((PomodoroEngine.Transition?, String) -> Void)?
    var onTaskDue: ((TaskItem) -> Void)?
    var onChatter: (() -> Void)?
    var tasks: TaskStore?
    private var nextChatter: Double = Date().timeIntervalSince1970 + Double.random(in: 90...180)
    var lineFor: ((PhraseBook.Event) -> String)?
    private var routine = RoutineEngine()
    var onRoutine: ((RoutineEngine.Event) -> Void)?
    var onNight: ((Bool) -> Void)?
    private var lastNight = false
    var secondsIdle: () -> Double = { 0 }
    private var now: Double { Date().timeIntervalSince1970 }
    private var observers: [NSObjectProtocol] = []
    private var sleeping = false

    init(settings: SettingsStore) {
        self.settings = settings
        pomodoro = PomodoroEngine(workMinutes: settings.pomodoroWork, breakMinutes: settings.pomodoroBreak)
        reconfigure()
        let t = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        let wnc = NSWorkspace.shared.notificationCenter
        let dnc = DistributedNotificationCenter.default()
        observers.append(wnc.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.setPaused(true, reason: "sleep") } })
        observers.append(wnc.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.setPaused(false, reason: "sleep") } })
        observers.append(dnc.addObserver(forName: Notification.Name("com.apple.screenIsLocked"), object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.setPaused(true, reason: "lock") } })
        observers.append(dnc.addObserver(forName: Notification.Name("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.setPaused(false, reason: "lock") } })
    }

    /// Call after settings change.
    func reconfigure() {
        var m: [ReminderKind: Int] = [:]
        if settings.waterEnabled { m[.water] = settings.waterMinutes }
        if settings.eyesEnabled { m[.eyes] = settings.eyesMinutes }
        if settings.postureEnabled { m[.posture] = settings.postureMinutes }
        scheduler.configure(m, at: now)
        pomodoro.workMinutes = settings.pomodoroWork
        pomodoro.breakMinutes = settings.pomodoroBreak
    }

    /// Pet is sleeping → no nagging.
    func setPetSleeping(_ s: Bool) { sleeping = s }

    func togglePomodoro() {
        if pomodoro.isRunning {
            pomodoro.stop()
            onPomodoro?(nil, lineFor?(.pomodoroStop) ?? Phrases.pomodoroStop.randomElement()!)
        } else {
            pomodoro = PomodoroEngine(workMinutes: settings.pomodoroWork, breakMinutes: settings.pomodoroBreak)
            pomodoro.start(at: now)
            onPomodoro?(.workStarted, lineFor?(.pomodoroStart) ?? Phrases.pomodoroStart.randomElement()!)
        }
    }

    var pomodoroStatus: String? {
        guard pomodoro.isRunning else { return nil }
        let r = pomodoro.remaining(at: now)
        return "\(pomodoro.phase == .work ? "Ish" : "Tanaffus") \(r / 60):\(String(format: "%02d", r % 60))"
    }

    private var pauseReasons: Set<String> = []
    private func setPaused(_ p: Bool, reason: String) {
        if p {
            scheduler.pause(at: now, reason: reason)
            if pauseReasons.isEmpty { pomodoro.pause(at: now) }
            pauseReasons.insert(reason)
        } else {
            scheduler.resume(at: now, reason: reason)
            pauseReasons.remove(reason)
            if pauseReasons.isEmpty { pomodoro.resume(at: now) }
        }
    }

    private func tick() {
        let t = now
        if let tr = pomodoro.tick(at: t) {
            let ev: PhraseBook.Event = tr == .breakStarted ? .breakStart : .workStart
            onPomodoro?(tr, lineFor?(ev) ?? (tr == .breakStarted ? Phrases.breakStart : Phrases.workStart).randomElement()!)
        }
        if let tasks { for task in tasks.dueTasks(at: Date()) { onTaskDue?(task) } }
        guard !sleeping else { return }
        for k in scheduler.due(at: t) {
            let ev: PhraseBook.Event = k == .water ? .water : (k == .eyes ? .eyes : .posture)
            onReminder?(k, lineFor?(ev) ?? Phrases.water.randomElement()!)
        }
        if t >= nextChatter {
            nextChatter = t + Double.random(in: 300...720)
            if secondsIdle() < 120 { onChatter?() }          // don't talk to an empty chair
        }
        for e in routine.events(at: Date()) { onRoutine?(e) }
        if let e = routine.idleEvent(secondsIdle: secondsIdle()) { onRoutine?(e) }
        let night = routine.isNight(at: Date())
        if night != lastNight { lastNight = night; onNight?(night) }
    }
}
