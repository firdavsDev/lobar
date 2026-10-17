import ServiceManagement

/// Wraps SMAppService.mainApp. Requires a bundled app with a stable identifier/signature.
enum LaunchAtLogin {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }
    static var requiresApproval: Bool { SMAppService.mainApp.status == .requiresApproval }

    /// Returns a user-facing Uzbek message on failure.
    static func toggle() -> String? {
        do {
            if isEnabled { try SMAppService.mainApp.unregister() } else { try SMAppService.mainApp.register() }
            if requiresApproval {
                return "Tizim sozlamalari → Umumiy → Login Items bo'limida ruxsat bering."
            }
            return nil
        } catch {
            return "Avtostartni o'zgartirib bo'lmadi: \(error.localizedDescription)"
        }
    }
}
