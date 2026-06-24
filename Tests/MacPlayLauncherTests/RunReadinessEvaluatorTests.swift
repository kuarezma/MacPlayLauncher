import Foundation
@testable import MacPlayLauncher
import XCTest

final class RunReadinessEvaluatorTests: XCTestCase {
    func testEmptyProfilesAreBlocked() {
        let result = evaluate(profiles: [], dependencies: readyDependencies())

        XCTAssertEqual(result.status, .blocked)
        XCTAssertEqual(result.blockers.first?.source, .gameProfile)
        XCTAssertEqual(
            result.blockers.first?.title,
            "Kullanıcı tarafından yapılandırılmış oyun profili bulunamadı."
        )
        XCTAssertFalse(result.canLaunch)
    }

    func testBundledSampleProfileRequiresUserSelectedLocalPaths() {
        let result = evaluate(profiles: [.sampleCossacks3], dependencies: readyDependencies())

        XCTAssertEqual(result.status, .blocked)
        XCTAssertEqual(result.blockers.first?.id, "game-profile.missing")
        XCTAssertFalse(result.canLaunch)
    }

    func testCrossOverProfileWithoutBottleNameIsBlocked() {
        let unconfigured = GameProfile(
            schemaVersion: GameProfile.currentSchemaVersion,
            id: "test-cx",
            displayName: "Test CX",
            executablePath: nil,
            workingDirectory: nil,
            prefixPath: "Prefixes/test-cx",
            executableBookmarkData: nil,
            workingDirectoryBookmarkData: nil,
            runtime: .crossOver,
            crossOverBottleName: nil,
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
        let result = evaluate(profiles: [unconfigured], dependencies: readyDependencies())

        XCTAssertEqual(result.status, .blocked)
        XCTAssertEqual(result.blockers.first?.id, "game-profile.missing")
        XCTAssertFalse(result.canLaunch)
    }

    func testMissingExecutablePathOrBookmarkIsBlocked() {
        var missingPath = configuredProfile()
        missingPath.executablePath = nil
        XCTAssertEqual(evaluate(profiles: [missingPath], dependencies: readyDependencies()).status, .blocked)

        var missingBookmark = configuredProfile()
        missingBookmark.executableBookmarkData = nil
        XCTAssertEqual(evaluate(profiles: [missingBookmark], dependencies: readyDependencies()).status, .blocked)
    }

    func testMissingWorkingDirectoryPathOrBookmarkIsBlocked() {
        var missingPath = configuredProfile()
        missingPath.workingDirectory = nil
        XCTAssertEqual(evaluate(profiles: [missingPath], dependencies: readyDependencies()).status, .blocked)

        var missingBookmark = configuredProfile()
        missingBookmark.workingDirectoryBookmarkData = nil
        XCTAssertEqual(evaluate(profiles: [missingBookmark], dependencies: readyDependencies()).status, .blocked)
    }

    func testConfiguredProfileWithWineMissingIsBlocked() {
        let result = evaluate(profiles: [configuredProfile()], dependencies: [
            dependency(kind: .wine, status: .missing, suggestedAction: "Wine için manuel kurulum rehberini izleyin.")
        ])

        XCTAssertEqual(result.status, .blocked)
        XCTAssertEqual(result.blockers.first?.title, "Gerekli bileşen eksik: Wine")
        XCTAssertEqual(result.blockers.first?.suggestedAction, "Wine için manuel kurulum rehberini izleyin.")
        XCTAssertFalse(result.canLaunch)
    }

    func testConfiguredProfileWithRosettaUnknownIsUnknown() {
        let result = evaluate(profiles: [configuredProfile()], dependencies: [
            dependency(kind: .rosetta, status: .unknown)
        ])

        XCTAssertEqual(result.status, .unknown)
        XCTAssertEqual(result.blockers.first?.title, "Bileşen durumu bilinmiyor: Rosetta")
        XCTAssertEqual(result.blockers.first?.severity, .warning)
        XCTAssertFalse(result.canLaunch)
    }

    func testUnsupportedDependencyHasPriority() {
        let result = evaluate(profiles: [configuredProfile()], dependencies: [
            dependency(kind: .wine, status: .missing),
            dependency(kind: .moltenVK, status: .unsupported)
        ])

        XCTAssertEqual(result.status, .unsupported)
        XCTAssertEqual(result.blockers.first?.title, "Desteklenmeyen bileşen: MoltenVK")
        XCTAssertEqual(result.blockers.first?.source, .unsupportedEnvironment)
        XCTAssertFalse(result.canLaunch)
    }

    func testReadyDependenciesAndConfiguredProfileAreReadyWithoutLaunch() {
        let result = evaluate(profiles: [configuredProfile()], dependencies: readyDependencies())

        XCTAssertEqual(result.status, .ready)
        XCTAssertTrue(result.blockers.isEmpty)
        XCTAssertFalse(result.canLaunch)
    }

    func testMultipleBlockersKeepDeterministicOrder() {
        // The bundled sample is no longer implicitly configured via a CrossOver bottle,
        // so the missing profile blocker appears before runtime blockers.
        let result = evaluate(profiles: [.sampleCossacks3], dependencies: [
            dependency(kind: .rosetta, status: .unknown),
            dependency(kind: .wine, status: .missing),
            dependency(kind: .moltenVK, status: .unsupported)
        ])

        XCTAssertEqual(result.status, .unsupported)
        XCTAssertEqual(result.blockers.map(\.id), [
            "game-profile.missing",
            "moltenVK.unsupported",
            "wine.missing",
            "rosetta.unknown"
        ])
    }

    func testSuggestedActionTextIsTurkishAndPassive() {
        let result = evaluate(profiles: [], dependencies: [
            dependency(kind: .dxvk, status: .missing, suggestedAction: nil)
        ])

        XCTAssertEqual(
            result.blockers.first?.suggestedAction,
            "Add Game ekranından oyun klasörünü ve çalıştırılabilir dosyayı seçin."
        )
        XCTAssertEqual(
            result.blockers.last?.suggestedAction,
            "Eksikler giderilmeden çalıştırma aktif olmayacak."
        )
    }

    func test_canLaunch_isFalse_whenStatusIsReady() {
        let result = evaluate(profiles: [configuredProfile()], dependencies: readyDependencies())
        XCTAssertEqual(result.status, .ready)
        XCTAssertFalse(result.canLaunch)
    }

    func test_canLaunch_isFalse_whenStatusIsBlocked() {
        let result = evaluate(profiles: [], dependencies: readyDependencies())
        XCTAssertEqual(result.status, .blocked)
        XCTAssertFalse(result.canLaunch)
    }

    func test_canLaunch_isFalse_whenStatusIsUnknown() {
        let result = evaluate(profiles: [configuredProfile()], dependencies: [dependency(kind: .rosetta, status: .unknown)])
        XCTAssertEqual(result.status, .unknown)
        XCTAssertFalse(result.canLaunch)
    }

    func test_canLaunch_isFalse_whenStatusIsUnsupported() {
        let result = evaluate(profiles: [configuredProfile()], dependencies: [dependency(kind: .wine, status: .unsupported)])
        XCTAssertEqual(result.status, .unsupported)
        XCTAssertFalse(result.canLaunch)
    }

    func testCanLaunchRemainsFalseForRealReadySummary() {
        let result = evaluate(
            profiles: [configuredProfile()],
            dependencies: [
                dependency(kind: .rosetta, status: .ready),
                dependency(kind: .wine, status: .ready),
                dependency(kind: .dxvk, status: .missing),
                dependency(kind: .moltenVK, status: .missing)
            ]
        )

        XCTAssertEqual(result.status, .blocked)
        XCTAssertFalse(result.canLaunch)
    }

    private func evaluate(
        profiles: [GameProfile],
        dependencies: [RuntimeDependency]
    ) -> RunReadinessResult {
        DefaultRunReadinessEvaluator().evaluate(
            profiles: profiles,
            diagnosticSummary: RuntimeDiagnosticSummary(dependencies: dependencies)
        )
    }

    private func readyDependencies() -> [RuntimeDependency] {
        [
            dependency(kind: .rosetta, status: .ready),
            dependency(kind: .wine, status: .ready),
            dependency(kind: .dxvk, status: .ready),
            dependency(kind: .moltenVK, status: .notRequired)
        ]
    }

    private func dependency(
        kind: RuntimeDependencyKind,
        status: RuntimeDependencyStatus,
        suggestedAction: String? = nil
    ) -> RuntimeDependency {
        RuntimeDependency(
            displayName: displayName(for: kind),
            kind: kind,
            status: status,
            version: nil,
            installPath: nil,
            userFacingDescription: "test",
            missingReason: nil,
            suggestedAction: suggestedAction,
            setupGuide: nil
        )
    }

    private func displayName(for kind: RuntimeDependencyKind) -> String {
        switch kind {
        case .rosetta:
            return "Rosetta"
        case .wine:
            return "Wine"
        case .dxvk:
            return "DXVK"
        case .moltenVK:
            return "MoltenVK"
        case .gameProfile:
            return "Oyun Profili"
        }
    }

    private func configuredProfile() -> GameProfile {
        GameProfile(
            schemaVersion: GameProfile.currentSchemaVersion,
            id: "configured-cossacks3",
            displayName: "Cossacks 3",
            executablePath: "/Games/Cossacks/cossacks3.exe",
            workingDirectory: "/Games/Cossacks",
            prefixPath: "Prefixes/configured-cossacks3",
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
