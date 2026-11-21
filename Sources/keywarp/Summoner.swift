import AppKit

@MainActor enum Summoner {
    /// Summons the Target, or Dismisses it if it's already frontmost.
    ///
    /// Uses LaunchServices (openApplication) even for running apps: since macOS 14,
    /// NSRunningApplication.activate() from a background app is only a request the
    /// system may silently ignore, and openApplication also gives Dock-click
    /// behaviour (unhide, restore a minimized window, reopen a window if none).
    static func summonOrDismiss(_ target: String) {
        let workspace = NSWorkspace.shared
        // Bundle identifiers are case-insensitive.
        if let frontmost = workspace.frontmostApplication,
           frontmost.bundleIdentifier?.caseInsensitiveCompare(target) == .orderedSame {
            // Hiding, like ⌘H, lets macOS bring forward another app, usually the previous one.
            // The result is ignored: on macOS 26 hide() returns false even when the app hides.
            _ = frontmost.hide()
            return
        }

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
