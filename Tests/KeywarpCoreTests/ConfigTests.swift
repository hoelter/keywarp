import Foundation
import KeywarpCore
import Testing

@Suite struct ConfigParsing {
    private func parse(_ json: String) throws(ConfigError) -> Config {
        try Config(parsing: Data(json.utf8))
    }

    @Test func parsesBindings() throws {
        let config = try parse("""
            {"bindings": [
              {"shortcut": "cmd+1", "app": "com.apple.Safari"},
              {"shortcut": "cmd+2", "app": "com.mitchellh.ghostty"}
            ]}
            """)
        #expect(config.bindings.map(\.target) == ["com.apple.Safari", "com.mitchellh.ghostty"])
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
        let error = #expect(throws: ConfigError.self) { try parse(json) }
        guard case .malformed = error?.problems.first else {
            Issue.record("expected .malformed, got \(String(describing: error))")
            return
        }
        #expect(error?.problems.count == 1)
    }

    @Test func namesTheUnknownKeyAndWhereItIs() {
        let error = #expect(throws: ConfigError.self) {
            try parse(#"{"bindings": [{"shortcut": "cmd+1", "app": "com.apple.Safari", "name": "Safari"}]}"#)
        }
        #expect(error?.problems.map(\.description) == [#"unknown key "name" at bindings[0]"#])
    }

    @Test func reportsEveryInvalidBinding() throws {
        let error = #expect(throws: ConfigError.self) {
            try parse("""
                {"bindings": [
                  {"shortcut": "opt+cmd+1", "app": "com.apple.Safari"},
                  {"shortcut": "alt+2", "app": "com.mitchellh.ghostty"},
                  {"shortcut": "cmd+3", "app": ""},
                  {"shortcut": "cmd+opt+1", "app": "com.spotify.client"}
                ]}
                """)
        }
        #expect(error?.problems == [
            .invalidShortcut(index: 1, .unknownModifier("alt", suggestion: "opt")),
            .emptyTarget(index: 2),
            .duplicateShortcut(index: 3, firstIndex: 0, try Shortcut(parsing: "cmd+opt+1")),
        ])
    }
}
