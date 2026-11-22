import AppKit
import KeywarpCore

@MainActor enum Summoner {
    /// Summons the Target, or Dismisses it if it's already frontmost.
    /// Always goes through LaunchServices: see docs/adr/0001-summon-through-launchservices.md.
    static func summonOrDismiss(_ target: Target) {
        let workspace = NSWorkspace.shared
        if let frontmost = workspace.frontmostApplication,
           frontmost.bundleIdentifier.flatMap(Target.init(bundleIdentifier:)) == target {
            // Hiding, like ⌘H, lets macOS bring forward another app, usually the previous one.
            // The result is ignored: on macOS 26 hide() returns false even when the app hides.
            _ = frontmost.hide()
            return
        }

        // Prefer the running copy so a second installed copy is never launched alongside it.
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: target.bundleIdentifier).first
        guard let url = running?.bundleURL ?? workspace.urlForApplication(withBundleIdentifier: target.bundleIdentifier) else {
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
