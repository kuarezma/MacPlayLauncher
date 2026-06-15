import XCTest
@testable import MacPlayLauncher

final class StaticDependencyDiagnosticServiceTests: XCTestCase {
    func testServiceReturnsDeterministicRuntimeDependencies() async {
        let service = StaticDependencyDiagnosticService()
        let summary = await service.loadSummary(profiles: [configuredProfile()])

        XCTAssertEqual(summary.dependencies.map(\.kind), [.rosetta, .wine, .dxvk, .moltenVK, .gameProfile])
        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .rosetta })?.status, .unknown)
        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .wine })?.status, .missing)
        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .dxvk })?.status, .missing)
        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .moltenVK })?.status, .missing)
        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .gameProfile })?.status, .ready)
    }

    func testGameProfileMissingWhenProfilesAreEmpty() async {
        let service = StaticDependencyDiagnosticService()
        let summary = await service.loadSummary(profiles: [])
        let gameProfile = summary.dependencies.first { $0.kind == .gameProfile }

        XCTAssertEqual(gameProfile?.status, .missing)
        XCTAssertEqual(gameProfile?.missingReason, String(localized: "diagnostics.gameProfile.missingReason"))
    }

    func testBundledSampleProfileIsNotReady() async {
        let service = StaticDependencyDiagnosticService()
        let summary = await service.loadSummary(profiles: [GameProfile.sampleCossacks3])
        let gameProfile = summary.dependencies.first { $0.kind == .gameProfile }

        XCTAssertEqual(gameProfile?.status, .missing)
        XCTAssertEqual(gameProfile?.userFacingDescription, String(localized: "diagnostics.gameProfile.missing"))
    }

    func testIncompleteProfileIsNotReady() async {
        let service = StaticDependencyDiagnosticService()
        var profile = configuredProfile()
        profile.executableBookmarkData = nil
        let summary = await service.loadSummary(profiles: [profile])
        let gameProfile = summary.dependencies.first { $0.kind == .gameProfile }

        XCTAssertEqual(gameProfile?.status, .missing)
    }

    func testConfiguredProfileIsReady() async {
        let service = StaticDependencyDiagnosticService()
        let summary = await service.loadSummary(profiles: [configuredProfile()])
        let gameProfile = summary.dependencies.first { $0.kind == .gameProfile }

        XCTAssertEqual(gameProfile?.status, .ready)
        XCTAssertEqual(gameProfile?.missingReason, nil)
        XCTAssertEqual(gameProfile?.suggestedAction, nil)
    }

    func testMissingDependencyHasTurkishSuggestedAction() async {
        let service = StaticDependencyDiagnosticService()
        let summary = await service.loadSummary(profiles: [GameProfile.sampleCossacks3])
        guard let wine = summary.dependencies.first(where: { $0.kind == .wine }) else {
            return XCTFail("Wine dependency should exist.")
        }

        XCTAssertEqual(wine.missingReason, String(localized: "diagnostics.wine.missing"))
        XCTAssertEqual(wine.suggestedAction, String(localized: "diagnostics.wine.suggestedAction"))
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
