import AppKit

/// Polls the window server for standable window top edges. No TCC permission needed:
/// only bounds/layer/pid/alpha are read (window names are gated and unused).
@MainActor
final class WindowSurfaceProvider {
    var onUpdate: (([Support]) -> Void)?
    /// When this returns false the poll is skipped (pet hidden or asleep).
    var isActive: () -> Bool = { true }
    private var timer: Timer?
    private var regularPIDs: [Int32: Bool] = [:]
    private var observers: [NSObjectProtocol] = []

    func start(interval: TimeInterval = 0.15) {
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        let nc = NSWorkspace.shared.notificationCenter
        for name in [NSWorkspace.didActivateApplicationNotification,
                     NSWorkspace.didTerminateApplicationNotification,
                     NSWorkspace.didLaunchApplicationNotification] {
            observers.append(nc.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.regularPIDs.removeAll(); self?.refresh() }
            })
        }
        refresh()
    }

    func stop() {
        timer?.invalidate(); timer = nil
        observers.forEach { NSWorkspace.shared.notificationCenter.removeObserver($0) }
        observers.removeAll()
    }

    func refresh() {
        guard isActive() else { return }
        onUpdate?(currentSupports())
    }

    func currentSupports() -> [Support] {
        guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
                as? [[String: Any]] else { return [] }
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
        var raws: [RawWindow] = []
        raws.reserveCapacity(list.count)
        for w in list {
            guard let number = w[kCGWindowNumber as String] as? Int,
                  let pid = w[kCGWindowOwnerPID as String] as? Int32,
                  let layer = w[kCGWindowLayer as String] as? Int,
                  let b = w[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = b["X"], let y = b["Y"], let wd = b["Width"], let ht = b["Height"] else { continue }
            let alpha = w[kCGWindowAlpha as String] as? Double ?? 1
            raws.append(RawWindow(number: number, pid: pid, layer: layer, alpha: alpha,
                                  bounds: CGRect(x: x, y: y, width: wd, height: ht)))
        }
        return SurfaceModel.supports(from: raws, primaryHeight: primaryHeight,
                                     selfPID: ProcessInfo.processInfo.processIdentifier,
                                     isRegularApp: { [self] pid in isRegular(pid) })
    }

    private func isRegular(_ pid: Int32) -> Bool {
        if let cached = regularPIDs[pid] { return cached }
        let regular = NSRunningApplication(processIdentifier: pid)?.activationPolicy == .regular
        regularPIDs[pid] = regular
        return regular
    }
}
