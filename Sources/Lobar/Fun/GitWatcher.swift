import Foundation

/// Polls a projects folder (depth ≤ 3) for new git commits by watching `.git/logs/HEAD` mtimes. No FSEvents, no permissions.
@MainActor
final class GitWatcher {
    private var timer: Timer?
    private var known: [String: Date] = [:]
    private var primed = false
    var onCommit: ((String) -> Void)?       // repo folder name

    func start(root: URL, interval: TimeInterval = 30) {
        stop()
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.scan(root: root) }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        scan(root: root)
    }

    func stop() { timer?.invalidate(); timer = nil; known.removeAll(); primed = false }

    private func scan(root: URL) {
        let fm = FileManager.default
        var found: [String: Date] = [:]
        func visit(_ dir: URL, depth: Int) {
            let head = dir.appendingPathComponent(".git/logs/HEAD")
            if let attrs = try? fm.attributesOfItem(atPath: head.path), let m = attrs[.modificationDate] as? Date {
                found[dir.lastPathComponent] = m
                return
            }
            guard depth < 3, let items = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.isDirectoryKey],
                                                                      options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { return }
            for u in items where (try? u.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
                if ["node_modules", ".build", "Pods", "build", "dist"].contains(u.lastPathComponent) { continue }
                visit(u, depth: depth + 1)
            }
        }
        visit(root, depth: 0)
        if primed {
            for (repo, m) in found where (known[repo].map { m > $0 } ?? false) { onCommit?(repo) }
        }
        known = found
        primed = true
    }
}
