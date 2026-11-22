import AppKit

let usage = """
    usage: keywarp            run in the background (started by `brew services start keywarp`)
           keywarp check      validate \(ConfigFile.url.path)
           keywarp --version
    """

switch Array(CommandLine.arguments.dropFirst()) {
case []:
    let app = NSApplication.shared
    let daemon = Daemon()
    daemon.start()
    app.run()
case ["check"]:
    exit(check())
case ["--version"]:
    guard let version = appBundle()?.infoDictionary?["CFBundleShortVersionString"] as? String else {
        printError("keywarp: version unknown, not running from Keywarp.app")
        exit(EXIT_FAILURE)
    }
    print(version)
default:
    printError(usage)
    exit(EX_USAGE)
}

func check() -> Int32 {
    let path = ConfigFile.url.path
    switch ConfigFile.load() {
    case .missing:
        printError("no config at \(path)")
        return EXIT_FAILURE
    case .unreadable(let error):
        printError("cannot read \(path): \(error.localizedDescription)")
        return EXIT_FAILURE
    case .invalid(let error):
        printError((["\(path) is invalid:"] + error.problems.map { "  \($0)" }).joined(separator: "\n"))
        return EXIT_FAILURE
    case .valid(let config):
        print("\(path) is valid:")
        for binding in config.bindings {
            let note = ConfigFile.isInstalled(binding.target) ? "" : "  (not installed)"
            print("  \(binding.shortcut) → \(binding.target)\(note)")
        }
        return EXIT_SUCCESS
    }
}

/// Bundle.main doesn't follow symlinks, and Homebrew's bin/keywarp is one.
func appBundle() -> Bundle? {
    guard let executable = Bundle.main.executableURL?.resolvingSymlinksInPath() else { return nil }
    return Bundle(url: executable.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent())
}
