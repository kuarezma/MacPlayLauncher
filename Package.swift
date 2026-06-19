// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacPlayLauncher",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "MacPlayLauncher", targets: ["MacPlayLauncher"])
    ],
    targets: [
        .executableTarget(
            name: "MacPlayLauncher",
            path: ".",
            exclude: ["build_output", "scripts", "Tests"],
            sources: ["App", "Core", "UI"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
