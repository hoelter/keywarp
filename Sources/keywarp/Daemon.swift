import AppKit
import Carbon.HIToolbox
import KeywarpCore

/// The background process: keeps the registered Shortcuts in step with the config file.
@MainActor final class Daemon {
    private let shortcuts = ShortcutRegistry(onPress: Summoner.summonOrDismiss)
    private var watcher: ConfigWatcher?

    func start() {
        do {
            try FileManager.default.createDirectory(at: ConfigFile.directory, withIntermediateDirectories: true)
        } catch {
            logger.error("cannot create \(ConfigFile.directory.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
        // Watch before the first load so a save in between isn't missed.
        let watcher = ConfigWatcher { [weak self] in self?.reload() }
        watcher.start()
        self.watcher = watcher
        reload()
    }

    /// Only a valid file is ever applied. Anything else keeps the current Shortcuts
    /// (none at startup), so a typo or a delete-then-write save can't drop them all.
    private func reload() {
        switch ConfigFile.load() {
        case .valid(let config):
            apply(config)
            return
        case .missing:
            logger.notice("no config at \(ConfigFile.url.path, privacy: .public)")
        case .unreadable(let error):
            logger.error("cannot read \(ConfigFile.url.path, privacy: .public): \(error.localizedDescription, privacy: .public)")
        case .invalid(let error):
            for problem in error.problems {
                logger.error("config rejected: \(problem, privacy: .public)")
            }
        }
        logger.notice("keeping \(self.shortcuts.count) current bindings")
    }

    private func apply(_ config: Config) {
        // A Binding whose Target isn't installed leaves its Shortcut free for other apps.
        var installed: [Binding] = []
        for binding in config.bindings {
            if ConfigFile.isInstalled(binding.target) {
                installed.append(binding)
            } else {
                logger.error("\(binding.shortcut, privacy: .public): \(binding.target, privacy: .public) is not installed; Shortcut left unbound")
            }
        }
        let failures = shortcuts.replace(with: installed)
        for (binding, status) in failures {
            let reason = status == OSStatus(eventHotKeyExistsErr) ? "another app already registered it" : "status \(status)"
            logger.error("cannot register \(binding.shortcut, privacy: .public) for \(binding.target, privacy: .public): \(reason, privacy: .public)")
        }
        logger.notice("loaded \(self.shortcuts.count) bindings")
    }
}
