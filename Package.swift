// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pinocator",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Pinocator",
            path: "Sources/Pinocator",
            resources: [.process("Resources")]
        )
    ]
)
