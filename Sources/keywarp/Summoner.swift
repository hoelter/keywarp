import AppKit

@MainActor enum Summoner {
    /// Brings the Target to the front as a Dock-icon click would, launching it if needed.
    ///
    /// Uses LaunchServices (openApplication) even for running apps: since macOS 14,
    /// NSRunningApplication.activate() from a background app is only a request the
    /// system may silently ignore, and openApplication also gives Dock-click
    /// behaviour (unhide, restore a minimized window, reopen a window if none).
    static func summon(_ target: String) {
        let workspace = NSWorkspace.shared
        guard workspace.frontmostApplication?.bundleIdentifier != target else { return }

        // Prefer the running copy so a second installed copy is never launched alongside it.
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: target).first
        guard let url = running?.bundleURL ?? workspace.urlForApplication(withBundleIdentifier: target) else {
            logger.error("\(target, privacy: .public) is not installed")
            return
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.addsToRecentItems = false
        workspace.openApplication(at: url, configuration: configuration) { @Sendable _, error in
            if let error {
                logger.error("summoning \(target, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
