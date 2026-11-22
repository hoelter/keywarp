import Foundation
import KeywarpCore
import Testing

@Suite struct ConfigParsing {
    private func parse(_ json: String) throws(ConfigError) -> Config {
        try Config(parsing: Data(json.utf8))
    }

    /// The problems a rejected file reports; empty if it was accepted.
    /// Catches explicitly because #expect(throws:) only returns the error from Swift 6.1.
    private func problems(_ json: String) -> [ConfigProblem] {
        do {
            _ = try parse(json)
            return []
        } catch {
            return error.problems
        }
    }

    @Test func parsesBindings() throws {
        let config = try parse("""
            {"bindings": [
              {"shortcut": "cmd+1", "app": "com.apple.Safari"},
              {"shortcut": "cmd+2", "app": "com.mitchellh.ghostty"}
            ]}
            """)
        #expect(config.bindings.map(\.target.bundleIdentifier) == ["com.apple.Safari", "com.mitchellh.ghostty"])
        #expect(config.bindings.map(\.shortcut.description) == ["cmd+1", "cmd+2"])
    }

    @Test func acceptsNoBindings() throws {
        #expect(try parse(#"{"bindings": []}"#).bindings.isEmpty)
    }

    @Test(arguments: [
        "not json",
        #"{"binding": []}"#,
        #"{"bindings": [{"shortcut": "cmd+1"}]}"#,
        #"{"bindings": [{"shortcut": 1, "app": "com.apple.Safari"}]}"#,
        #"{"bindings": [{"shortcut": "cmd+1", "app": "com.apple.Safari", "name": "Safari"}]}"#,
        #"{"bindings": [], "version": 1}"#,
    ])
    func rejectsMalformedFile(json: String) {
        let problems = problems(json)
        guard problems.count == 1, case .malformed = problems[0] else {
            Issue.record("expected one .malformed problem, got \(problems)")
            return
        }
    }

    @Test func namesTheUnknownKeyAndWhereItIs() {
        let problems = problems(#"{"bindings": [{"shortcut": "cmd+1", "app": "com.apple.Safari", "name": "Safari"}]}"#)
        #expect(problems.map(\.description) == [#"unknown key "name" at bindings[0]"#])
    }

    @Test func reportsEveryInvalidBinding() throws {
        let problems = problems("""
            {"bindings": [
              {"shortcut": "opt+cmd+1", "app": "com.apple.Safari"},
              {"shortcut": "alt+2", "app": "com.mitchellh.ghostty"},
              {"shortcut": "cmd+3", "app": ""},
              {"shortcut": "cmd+opt+1", "app": "com.spotify.client"},
              {"shortcut": "1", "app": "com.apple.Safari "}
            ]}
            """)
        #expect(problems == [
            .invalidShortcut(index: 1, .unknownModifier("alt", suggestion: "opt")),
            .invalidTarget(index: 2, ""),
            .duplicateShortcut(index: 3, firstIndex: 0, try Shortcut(parsing: "cmd+opt+1")),
            .invalidShortcut(index: 4, .missingModifier),
            .invalidTarget(index: 4, "com.apple.Safari "),
        ])
    }
}
