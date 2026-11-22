import Foundation

/// One Shortcut paired with one Target.
public struct Binding: Equatable, Sendable {
    public let shortcut: Shortcut
    public let target: Target
}

/// A fully valid set of Bindings. A file with any problem yields no Config at all.
public struct Config: Equatable, Sendable {
    public let bindings: [Binding]

    public init(parsing data: Data) throws(ConfigError) {
        let file: File
        do {
            file = try JSONDecoder().decode(File.self, from: data)
        } catch let error as DecodingError {
            throw ConfigError(problems: [.malformed(Self.describe(error))])
        } catch {
            preconditionFailure("JSONDecoder threw a non-DecodingError: \(error)")
        }

        var bindings: [Binding] = []
        var problems: [ConfigProblem] = []
        var firstIndexByShortcut: [Shortcut: Int] = [:]
        for (index, entry) in file.bindings.enumerated() {
            let shortcut: Shortcut?
            do {
                shortcut = try Shortcut(parsing: entry.shortcut)
            } catch {
                problems.append(.invalidShortcut(index: index, error))
                shortcut = nil
            }
            let target = Target(bundleIdentifier: entry.app)
            if target == nil {
                problems.append(.invalidTarget(index: index, entry.app))
            }
            guard let shortcut, let target else { continue }
            if let firstIndex = firstIndexByShortcut[shortcut] {
                problems.append(.duplicateShortcut(index: index, firstIndex: firstIndex, shortcut))
                continue
            }
            firstIndexByShortcut[shortcut] = index
            bindings.append(Binding(shortcut: shortcut, target: target))
        }
        guard problems.isEmpty else { throw ConfigError(problems: problems) }
        self.bindings = bindings
    }

    private struct File: Decodable {
        let bindings: [Entry]
        enum CodingKeys: String, CodingKey, CaseIterable { case bindings }

        init(from decoder: Decoder) throws {
            let container = try strictContainer(decoder, keyedBy: CodingKeys.self)
            bindings = try container.decode([Entry].self, forKey: .bindings)
        }

        struct Entry: Decodable {
            let shortcut: String
            let app: String
            enum CodingKeys: String, CodingKey, CaseIterable { case shortcut, app }

            init(from decoder: Decoder) throws {
                let container = try strictContainer(decoder, keyedBy: CodingKeys.self)
                shortcut = try container.decode(String.self, forKey: .shortcut)
                app = try container.decode(String.self, forKey: .app)
            }
        }
    }

    private static func describe(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, let context):
            return "missing \"\(key.stringValue)\" at \(path(context))"
        case .typeMismatch(_, let context), .valueNotFound(_, let context):
            return "wrong type at \(path(context))"
        case .dataCorrupted(let context) where context.underlyingError != nil:
            return "not valid JSON: \(context.underlyingError!.localizedDescription)"
        case .dataCorrupted(let context):
            return "\(context.debugDescription) at \(path(context))"
        @unknown default:
            return error.localizedDescription
        }
    }

    private static func path(_ context: DecodingError.Context) -> String {
        let path = context.codingPath.map { $0.intValue.map { "[\($0)]" } ?? ".\($0.stringValue)" }.joined()
        return path.isEmpty ? "top level" : String(path.drop(while: { $0 == "." }))
    }
}

/// A keyed container that rejects keys it doesn't declare, so a misspelled or
/// unsupported key is an error rather than silently ignored.
private func strictContainer<Key: CodingKey & CaseIterable>(
    _ decoder: Decoder, keyedBy: Key.Type
) throws -> KeyedDecodingContainer<Key> {
    let allowed = Set(Key.allCases.map(\.stringValue))
    let any = try decoder.container(keyedBy: AnyKey.self)
    if let unknown = any.allKeys.first(where: { !allowed.contains($0.stringValue) }) {
        throw DecodingError.dataCorrupted(.init(codingPath: any.codingPath,
                                                debugDescription: "unknown key \"\(unknown.stringValue)\""))
    }
    return try decoder.container(keyedBy: Key.self)
}

private struct AnyKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

public struct ConfigError: Error, Equatable, Sendable {
    public let problems: [ConfigProblem]
}

public enum ConfigProblem: Equatable, Sendable, CustomStringConvertible {
    case malformed(String)
    case invalidShortcut(index: Int, ShortcutError)
    case invalidTarget(index: Int, String)
    case duplicateShortcut(index: Int, firstIndex: Int, Shortcut)

    public var description: String {
        switch self {
        case .malformed(let reason):
            reason
        case .invalidShortcut(let index, let error):
            "bindings[\(index)]: \(error)"
        case .invalidTarget(let index, let target):
            "bindings[\(index)]: \"app\" must be a bundle identifier like com.apple.Safari, got \"\(target)\""
        case .duplicateShortcut(let index, let firstIndex, let shortcut):
            "bindings[\(index)]: \(shortcut) is already bound by bindings[\(firstIndex)]"
        }
    }
}
