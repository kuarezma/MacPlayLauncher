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

    func testViewModelMapsReadinessStatusTitles() {
        let viewModel = DiagnosticsViewModel()

        XCTAssertEqual(viewModel.readinessBadgeText(for: .ready), String(localized: "readiness.ready.title"))
        XCTAssertEqual(viewModel.readinessBadgeText(for: .blocked), String(localized: "readiness.blocked.title"))
        XCTAssertEqual(viewModel.readinessBadgeText(for: .unknown), String(localized: "readiness.unknown.title"))
        XCTAssertEqual(viewModel.readinessBadgeText(for: .unsupported), String(localized: "readiness.unsupported.title"))
    }

    func testViewModelMapsReadinessSeverityLabels() {
        let viewModel = DiagnosticsViewModel()

        XCTAssertEqual(viewModel.severityText(for: .info), String(localized: "readiness.severity.info"))
        XCTAssertEqual(viewModel.severityText(for: .warning), String(localized: "readiness.severity.warning"))
        XCTAssertEqual(viewModel.severityText(for: .blocking), String(localized: "readiness.severity.blocking"))
    }

    func testViewModelHandlesEmptyReadinessInputs() {
        let viewModel = DiagnosticsViewModel()
        viewModel.update(
            summary: RuntimeDiagnosticSummary(dependencies: []),
            readinessResult: RunReadinessResult(
                status: .blocked,
                title: String(localized: "readiness.blocked.title"),
                message: String(localized: "readiness.fixMissingBeforeLaunch"),
                blockers: [],
                canLaunch: false
            )
        )

        XCTAssertEqual(viewModel.dependencies, [])
        XCTAssertEqual(viewModel.readinessBlockers, [])
        XCTAssertEqual(viewModel.readinessTitle, String(localized: "readiness.blocked.title"))
    }

    func testViewModelProvidesLaunchNotImplementedText() {
        let viewModel = DiagnosticsViewModel()

        XCTAssertEqual(viewModel.launchNotImplementedText, String(localized: "readiness.launchNotImplemented"))
        XCTAssertEqual(viewModel.noLaunchThisSprintText, String(localized: "readiness.noLaunchThisSprint"))
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
