// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Lobar",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "Lobar",
            path: "Sources/Lobar",
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "LobarTests",
            dependencies: ["Lobar"],
            path: "Tests/LobarTests"
        ),
    ]
)
