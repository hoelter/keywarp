/// A key combination: one or more modifiers plus a single key, e.g. `cmd+1`.
public struct Shortcut: Hashable, Sendable, CustomStringConvertible {
    public let modifiers: Modifiers
    /// Virtual key code of the key's physical position on a US ANSI keyboard.
    public let keyCode: UInt32
    private let keyName: String

    public init(parsing text: String) throws(ShortcutError) {
        let tokens = text.lowercased().split(separator: "+", omittingEmptySubsequences: false).map(String.init)
        var modifiers: Modifiers = []
        for token in tokens.dropLast() {
            guard let modifier = Modifiers(name: token) else {
                throw .unknownModifier(token, suggestion: Modifiers.suggestions[token])
            }
            guard modifiers.insert(modifier).inserted else { throw .repeatedModifier(token) }
        }
        let keyName = tokens.last!
        guard let keyCode = Key.codes[keyName] else {
            throw .unknownKey(keyName, suggestion: Key.suggestions[keyName])
        }
        // Shift alone would swallow ordinary typing, e.g. capital letters.
        guard !modifiers.isDisjoint(with: [.cmd, .ctrl, .opt]) else { throw .missingModifier }
        self.modifiers = modifiers
        self.keyCode = keyCode
        self.keyName = keyName
    }

    /// Canonical spelling, modifiers in macOS menu order (⌃⌥⇧⌘).
    public var description: String {
        (Modifiers.canonicalOrder.filter { modifiers.contains($0.modifier) }.map(\.name) + [keyName])
            .joined(separator: "+")
    }
}

public struct Modifiers: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let cmd = Modifiers(rawValue: 1 << 0)
    public static let ctrl = Modifiers(rawValue: 1 << 1)
    public static let opt = Modifiers(rawValue: 1 << 2)
    public static let shift = Modifiers(rawValue: 1 << 3)

    static let canonicalOrder: [(name: String, modifier: Modifiers)] = [
        ("ctrl", .ctrl), ("opt", .opt), ("shift", .shift), ("cmd", .cmd),
    ]

    static let suggestions = ["command": "cmd", "control": "ctrl", "alt": "opt", "option": "opt"]

    init?(name: String) {
        guard let match = Self.canonicalOrder.first(where: { $0.name == name }) else { return nil }
        self = match.modifier
    }
}

public enum ShortcutError: Error, Equatable, Sendable, CustomStringConvertible {
    case unknownModifier(String, suggestion: String?)
    case repeatedModifier(String)
    case unknownKey(String, suggestion: String?)
    /// Needs at least one of cmd, ctrl or opt.
    case missingModifier

    public var description: String {
        switch self {
        case .unknownModifier(let name, let suggestion):
            "unknown modifier \"\(name)\"" + Self.hint(suggestion) + "; use cmd, ctrl, opt or shift"
        case .repeatedModifier(let name):
            "modifier \"\(name)\" appears more than once"
        case .unknownKey(let name, let suggestion):
            "unknown key \"\(name)\"" + Self.hint(suggestion)
        case .missingModifier:
            "needs at least one of cmd, ctrl or opt"
        }
    }

    private static func hint(_ suggestion: String?) -> String {
        suggestion.map { " (did you mean \"\($0)\"?)" } ?? ""
    }
}
