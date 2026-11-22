import KeywarpCore
import Testing

@Suite struct TargetIdentity {
    @Test func acceptsBundleIdentifierAndKeepsItsSpelling() throws {
        let target = try #require(Target(bundleIdentifier: "com.apple.Safari"))
        #expect(target.bundleIdentifier == "com.apple.Safari")
    }

    @Test(arguments: ["", "com.apple.Safari ", "com.apple.Säfari"])
    func rejectsInvalidBundleIdentifier(text: String) {
        #expect(Target(bundleIdentifier: text) == nil)
    }

    @Test func comparesCaseInsensitively() throws {
        let safari = try #require(Target(bundleIdentifier: "com.apple.Safari"))
        let lowercased = try #require(Target(bundleIdentifier: "com.apple.safari"))
        #expect(safari == lowercased)
        #expect(safari.hashValue == lowercased.hashValue)
        #expect(safari != (try #require(Target(bundleIdentifier: "com.apple.Notes"))))
    }
}
