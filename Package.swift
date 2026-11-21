// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "keywarp",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "KeywarpCore"),
        .executableTarget(name: "keywarp", dependencies: ["KeywarpCore"]),
        .testTarget(name: "KeywarpCoreTests", dependencies: ["KeywarpCore"]),
    ]
)
