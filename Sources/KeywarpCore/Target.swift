import Foundation

/// The application a Shortcut points to, identified by its bundle identifier.
/// Bundle identifiers are case-insensitive, so equality ignores case, but the original
/// spelling is kept for display and lookups.
public struct Target: Hashable, Sendable, CustomStringConvertible {
    public let bundleIdentifier: String
    /// Lowercasing is exact case folding here because the identifier is ASCII-only.
    private let caseFoldedIdentifier: String

    /// Apple allows only ASCII letters, digits, hyphens and periods in a bundle identifier.
    public init?(bundleIdentifier: String) {
        let isValid = !bundleIdentifier.isEmpty && bundleIdentifier.unicodeScalars.allSatisfy {
            $0.isASCII && (CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == ".")
        }
        guard isValid else { return nil }
        self.bundleIdentifier = bundleIdentifier
        caseFoldedIdentifier = bundleIdentifier.lowercased()
    }

    public static func == (lhs: Target, rhs: Target) -> Bool { lhs.caseFoldedIdentifier == rhs.caseFoldedIdentifier }
    public func hash(into hasher: inout Hasher) { hasher.combine(caseFoldedIdentifier) }

    public var description: String { bundleIdentifier }
}
