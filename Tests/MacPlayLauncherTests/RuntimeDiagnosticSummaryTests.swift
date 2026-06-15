import XCTest
@testable import MacPlayLauncher

final class RuntimeDiagnosticSummaryTests: XCTestCase {
    func testAllReadyDependenciesMakeSummaryReady() {
        let summary = RuntimeDiagnosticSummary(dependencies: [
            makeDependency(kind: .rosetta, status: .ready),
            makeDependency(kind: .wine, status: .ready),
            makeDependency(kind: .dxvk, status: .ready),
            makeDependency(kind: .moltenVK, status: .ready),
            makeDependency(kind: .gameProfile, status: .ready)
        ])

        XCTAssertEqual(summary.overallStatus, .ready)
    }

    func testMissingWineMakesSummaryMissingDependencies() {
        let summary = RuntimeDiagnosticSummary(dependencies: [
            makeDependency(kind: .wine, status: .missing),
            makeDependency(kind: .gameProfile, status: .ready)
        ])

        XCTAssertEqual(summary.overallStatus, .hasMissingDependencies)
    }

    func testUnknownRosettaMakesSummaryUnknownWhenNothingIsMissing() {
        let summary = RuntimeDiagnosticSummary(dependencies: [
            makeDependency(kind: .rosetta, status: .unknown),
            makeDependency(kind: .gameProfile, status: .ready)
        ])

        XCTAssertEqual(summary.overallStatus, .unknown)
    }

    private func makeDependency(kind: RuntimeDependencyKind, status: RuntimeDependencyStatus) -> RuntimeDependency {
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
}
