import KeywarpCore
import Testing

@Suite struct ShortcutParsing {
    @Test func parsesCommandDigit() throws {
        let shortcut = try Shortcut(parsing: "cmd+1")
        #expect(shortcut.modifiers == [.cmd])
        #expect(shortcut.keyCode == 18)
    }

    @Test func modifierOrderAndCaseDoNotMatter() throws {
        let shortcut = try Shortcut(parsing: "Shift+CMD+Ctrl+opt+K")
        #expect(shortcut == (try Shortcut(parsing: "ctrl+opt+shift+cmd+k")))
        #expect(shortcut.modifiers == [.cmd, .ctrl, .opt, .shift])
        #expect(shortcut.keyCode == 40)
    }

    @Test func printsInCanonicalOrder() throws {
        #expect((try Shortcut(parsing: "shift+cmd+opt+ctrl+f5")).description == "ctrl+opt+shift+cmd+f5")
    }

    @Test(arguments: [
        ("1", ShortcutError.missingModifier),
        ("shift+a", .missingModifier),
        ("alt+1", .unknownModifier("alt", suggestion: "opt")),
        ("command+1", .unknownModifier("command", suggestion: "cmd")),
        ("hyper+1", .unknownModifier("hyper", suggestion: nil)),
        ("cmd+cmd+1", .repeatedModifier("cmd")),
        ("cmd+enter", .unknownKey("enter", suggestion: "return")),
        ("cmd+", .unknownKey("", suggestion: nil)),
        ("cmd + 1", .unknownModifier("cmd ", suggestion: nil)),
    ])
    func rejects(text: String, expected: ShortcutError) {
        #expect(throws: expected) { try Shortcut(parsing: text) }
    }
}
