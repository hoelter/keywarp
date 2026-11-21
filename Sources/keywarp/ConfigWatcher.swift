import Foundation

/// Calls `onChange` after the config file changes. Watches the directory too, because
/// editors that save atomically replace the file rather than writing to it.
/// Kernel-driven (kqueue), so it costs nothing while idle.
@MainActor final class ConfigWatcher {
    private let onChange: @MainActor () -> Void
    private var directorySource: DispatchSourceFileSystemObject?
    private var fileSource: DispatchSourceFileSystemObject?
    private var pendingChange: DispatchWorkItem?

    init(onChange: @escaping @MainActor () -> Void) {
        self.onChange = onChange
    }

    func start() {
        directorySource = makeSource(ConfigFile.directory, events: .write)
        if directorySource == nil {
            logger.error("cannot watch \(ConfigFile.directory.path, privacy: .public); config changes need a restart")
        }
        watchFile()
    }

    /// Re-attaches to whatever file is now at the config path; nil while it doesn't exist.
    private func watchFile() {
        fileSource?.cancel()
        fileSource = makeSource(ConfigFile.url, events: [.write, .extend, .delete, .rename])
    }

    private func makeSource(_ url: URL, events: DispatchSource.FileSystemEvent) -> DispatchSourceFileSystemObject? {
        let descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return nil }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: descriptor, eventMask: events, queue: .main)
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.changed() }
        }
        source.setCancelHandler { close(descriptor) }
        source.resume()
        return source
    }

    /// Coalesces the burst of events a single save produces into one reload.
    private func changed() {
        pendingChange?.cancel()
        let change = DispatchWorkItem { [weak self] in
            MainActor.assumeIsolated {
                self?.watchFile()
                self?.onChange()
            }
        }
        pendingChange = change
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100), execute: change)
    }
}
