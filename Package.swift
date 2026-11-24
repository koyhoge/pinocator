// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Pinocator",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Pinocator", path: "Sources/Pinocator")
    ]
)
