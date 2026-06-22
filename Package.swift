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
            exclude: [
                "ARCHITECTURE.md",
                "DEVELOPMENT.md",
                "Docs",
                "MacPlay.entitlements",
                "README.md",
                "build_output",
                "project.yml",
                "script",
                "scripts",
                "Tests"
            ],
            sources: ["App", "Core", "UI"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MacPlayLauncherTests",
            dependencies: ["MacPlayLauncher"],
            path: "Tests/MacPlayLauncherTests",
            exclude: ["Fixtures"],
            resources: [
                .copy("../../Resources/Profiles/cossacks3.profile.json")
            ]
        )
    ]
)
