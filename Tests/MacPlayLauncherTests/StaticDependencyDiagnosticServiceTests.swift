import XCTest
@testable import MacPlayLauncher

final class StaticDependencyDiagnosticServiceTests: XCTestCase {
    func testServiceReturnsDeterministicRuntimeDependencies() async {
        let service = StaticDependencyDiagnosticService()
        let summary = await service.loadSummary(profiles: [GameProfile.sampleCossacks3])

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

    func testMissingDependencyHasTurkishSuggestedAction() async {
        let service = StaticDependencyDiagnosticService()
        let summary = await service.loadSummary(profiles: [GameProfile.sampleCossacks3])
        guard let wine = summary.dependencies.first(where: { $0.kind == .wine }) else {
            return XCTFail("Wine dependency should exist.")
        }

        XCTAssertEqual(wine.missingReason, String(localized: "diagnostics.wine.missing"))
        XCTAssertEqual(wine.suggestedAction, String(localized: "diagnostics.wine.suggestedAction"))
    }
}
