import Foundation

enum Paths {
    static var appSupport: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Rayxon", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    static var memoryFile: URL { appSupport.appendingPathComponent("memory.json") }
    static var tasksFile: URL { appSupport.appendingPathComponent("tasks.json") }
    static var statsFile: URL { appSupport.appendingPathComponent("stats.json") }
}
