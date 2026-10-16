// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Rayxon",
    platforms: [.macOS(.v15)],
    targets: [
        .executableTarget(
            name: "Rayxon",
            path: "Sources/Rayxon",
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "RayxonTests",
            dependencies: ["Rayxon"],
            path: "Tests/RayxonTests"
        ),
    ]
)
