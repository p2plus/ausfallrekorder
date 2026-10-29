// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Ausfallrekorder",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Ausfallrekorder", targets: ["Ausfallrekorder"]),
        .executable(name: "ausfallrekorder-cli", targets: ["RecorderCLI"])
    ],
    targets: [
        .target(name: "RecorderCore"),
        .executableTarget(name: "RecorderCLI", dependencies: ["RecorderCore"]),
        .executableTarget(name: "Ausfallrekorder", dependencies: ["RecorderCore"]),
        .testTarget(name: "RecorderCoreTests", dependencies: ["RecorderCore"])
    ]
)
