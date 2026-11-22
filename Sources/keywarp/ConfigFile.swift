import AppKit
import KeywarpCore

enum ConfigFile {
    static let directory = FileManager.default.homeDirectoryForCurrentUser
        .appending(path: ".config/keywarp", directoryHint: .isDirectory)
    static let url = directory.appending(path: "config.json")

    enum Loaded {
        case missing
        case unreadable(any Error)
        case invalid(ConfigError)
        case valid(Config)
    }

    static func load() -> Loaded {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return .missing
        } catch {
            return .unreadable(error)
        }
        do {
            return .valid(try Config(parsing: data))
        } catch {
            return .invalid(error)
        }
    }

    /// Not a config error, so one config can be shared between Macs with different apps installed.
    static func isInstalled(_ target: Target) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: target.bundleIdentifier) != nil
    }
}
