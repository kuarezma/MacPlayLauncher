@testable import MacPlayLauncher
import XCTest

final class ExperimentalRunReadinessEvaluatorTests: XCTestCase {
    func testExperimentalLaunchRequiresRealDiagnostics() {
        let result = evaluate(
            summary: staticSummary(),
            prefixExists: true,
            wineExists: true
        )

        XCTAssertFalse(result.canLaunch)
        XCTAssertTrue(result.blockers.contains { $0.id == "experimental.requiresRealDiagnostics" })
    }

    func testExperimentalLaunchEnabledWhenRealChecksPassAndPrefixExists() {
        let result = evaluate(
            summary: realReadySummary(),
            prefixExists: true,
            wineExists: true
        )

        XCTAssertTrue(result.canLaunch)
        XCTAssertEqual(result.status, .ready)
    }

    func testExperimentalLaunchBlockedWhenPrefixMissing() {
        let result = evaluate(
            summary: realReadySummary(),
            prefixExists: false,
            wineExists: true
        )

        XCTAssertFalse(result.canLaunch)
        XCTAssertTrue(result.blockers.contains { $0.id == "experimental.prefix.missing" })
    }

    func testDefaultReadinessEvaluatorStillBlocksLaunch() {
        let result = DefaultRunReadinessEvaluator().evaluate(
            profiles: [configuredProfile()],
            diagnosticSummary: realReadySummary()
        )

        XCTAssertFalse(result.canLaunch)
    }

    private func evaluate(
        summary: RuntimeDiagnosticSummary,
        prefixExists: Bool,
        wineExists: Bool
    ) -> RunReadinessResult {
        let prefixURL = URL(fileURLWithPath: "/tmp/prefix", isDirectory: true)
        let evaluator = ExperimentalRunReadinessEvaluator(
            prefixManager: FakeLaunchPrefixManager(prefixURL: prefixExists ? prefixURL : nil),
            policy: .experimental,
            wineResolver: WineExecutableResolver(
                fileChecker: FakeLaunchFileChecker(
                    existingExecutables: wineExists ? ["/opt/homebrew/bin/wine"] : []
                )
            )
        )

        return evaluator.evaluate(
            profiles: [configuredProfile()],
            diagnosticSummary: summary
        )
    }

    private func staticSummary() -> RuntimeDiagnosticSummary {
        RuntimeDiagnosticSummary(
            dependencies: [
                dependency(kind: .wine, status: .missing),
                dependency(kind: .gameProfile, status: .ready)
            ],
            source: .staticPreparation
        )
    }

    private func realReadySummary() -> RuntimeDiagnosticSummary {
        RuntimeDiagnosticSummary(
            dependencies: [
                dependency(kind: .rosetta, status: .ready),
                dependency(kind: .wine, status: .ready),
                dependency(kind: .dxvk, status: .missing),
                dependency(kind: .moltenVK, status: .missing),
                dependency(kind: .gameProfile, status: .ready)
            ],
            source: .realSystemCheck
        )
    }

    private func dependency(kind: RuntimeDependencyKind, status: RuntimeDependencyStatus) -> RuntimeDependency {
        RuntimeDependency(
            displayName: kind.rawValue,
            kind: kind,
            status: status,
            version: nil,
            installPath: nil,
            userFacingDescription: "test",
            missingReason: nil,
            suggestedAction: nil,
            setupGuide: nil
        )
    }

    private func configuredProfile() -> GameProfile {
        GameProfile(
            schemaVersion: GameProfile.currentSchemaVersion,
            id: "test-game",
            displayName: "Test Game",
            executablePath: "/Games/Cossacks/cossacks3.exe",
            workingDirectory: "/Games/Cossacks",
            prefixPath: "Prefixes/test-game",
            executableBookmarkData: Data([1]),
            workingDirectoryBookmarkData: Data([2]),
            runtime: .wineDXVKMoltenVK,
            performanceMode: .balanced,
            wineArch: .win64,
            windowsVersion: .win10,
            dependencies: [],
            environment: [:],
            launchArguments: [],
            knownIssues: [],
            lastPlayedAt: nil,
            totalPlayTimeMinutes: 0,
            launchCount: 0
        )
    }
}

private final class FakeLaunchPrefixManager: PrefixManaging {
    let prefixURL: URL?

    init(prefixURL: URL?) {
        self.prefixURL = prefixURL
    }

    func directoryState(for profile: GameProfile) throws -> PrefixDirectoryState {
        PrefixDirectoryState(
            profileID: profile.id,
            displayName: profile.displayName,
            relativePath: profile.prefixPath,
            absolutePath: prefixURL?.path ?? "/missing",
            availability: prefixURL == nil ? .missing : .exists
        )
    }

    func createPrefixDirectory(for profile: GameProfile) throws -> PrefixDirectoryState {
        try directoryState(for: profile)
    }
}

private struct FakeLaunchFileChecker: FileChecking {
    let existingExecutables: [String]

    func fileExists(at url: URL) -> Bool {
        existingExecutables.contains(url.path)
    }

    func isExecutableFile(at url: URL) -> Bool {
        existingExecutables.contains(url.path)
    }
}
