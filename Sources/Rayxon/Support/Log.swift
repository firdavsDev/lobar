import os

enum Log {
    static let subsystem = "dev.davronbek.rayxon"
    static let app = Logger(subsystem: subsystem, category: "app")
    static let pet = Logger(subsystem: subsystem, category: "pet")
    static let chat = Logger(subsystem: subsystem, category: "chat")
    static let voice = Logger(subsystem: subsystem, category: "voice")
}
