import XCTest
@testable import MacPlayLauncher

@MainActor
final class DiagnosticsViewModelTests: XCTestCase {
    func testViewModelMapsMissingSummary() {
        let viewModel = DiagnosticsViewModel()
        viewModel.update(summary: RuntimeDiagnosticSummary(dependencies: [
            makeDependency(kind: .wine, status: .missing)
        ]))

        XCTAssertEqual(viewModel.overallTitle, String(localized: "diagnostics.overall.missing"))
        XCTAssertEqual(viewModel.badgeText(for: .missing), String(localized: "diagnostics.status.missing"))
    }

    func testViewModelMapsUnknownRosetta() {
        let viewModel = DiagnosticsViewModel()
        viewModel.update(summary: RuntimeDiagnosticSummary(dependencies: [
            makeDependency(kind: .rosetta, status: .unknown)
        ]))

        XCTAssertEqual(viewModel.overallTitle, String(localized: "diagnostics.overall.unknown"))
        XCTAssertEqual(viewModel.badgeText(for: .unknown), String(localized: "diagnostics.status.unknown"))
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
