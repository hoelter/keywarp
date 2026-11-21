import Foundation
import os

/// Read with: /usr/bin/log stream --predicate 'subsystem == "io.github.hoelter.keywarp"'
let logger = Logger(subsystem: "io.github.hoelter.keywarp", category: "keywarp")

func printError(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}
