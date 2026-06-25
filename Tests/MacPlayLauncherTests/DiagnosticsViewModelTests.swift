@testable import MacPlayLauncher
import XCTest

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
        XCTAssertEqual(
            viewModel.readinessBadgeText(for: .unsupported),
            String(localized: "readiness.unsupported.title")
        )
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

    func testStaticSourceInfoCardMapping() {
        let viewModel = DiagnosticsViewModel()
        viewModel.update(
            summary: RuntimeDiagnosticSummary(
                dependencies: [makeDependency(kind: .wine, status: .missing)],
                source: .staticPreparation
            )
        )

        XCTAssertEqual(viewModel.sourceTitle, String(localized: "diagnostics.source.static.title"))
        XCTAssertEqual(viewModel.sourceSubtitle, String(localized: "diagnostics.source.static.subtitle"))
        XCTAssertEqual(viewModel.sourceNote, String(localized: "diagnostics.source.static.note"))
        XCTAssertEqual(viewModel.sourceBadgeText, String(localized: "diagnostics.source.static.badge"))
        XCTAssertEqual(viewModel.sourceNoInstallNote, String(localized: "diagnostics.source.noInstall"))
        XCTAssertEqual(viewModel.sourceDxvkMoltenVKLaterNote, String(localized: "diagnostics.source.dxvkMoltenVKLater"))
    }

    func testRealSourceInfoCardMapping() {
        let viewModel = DiagnosticsViewModel()
        viewModel.update(
            summary: RuntimeDiagnosticSummary(
                dependencies: [makeDependency(kind: .wine, status: .ready)],
                source: .realSystemCheck
            )
        )

        XCTAssertEqual(viewModel.sourceTitle, String(localized: "diagnostics.source.real.title"))
        XCTAssertEqual(viewModel.sourceSubtitle, String(localized: "diagnostics.source.real.subtitle"))
        XCTAssertNil(viewModel.sourceNote)
        XCTAssertEqual(viewModel.sourceBadgeText, String(localized: "diagnostics.source.real.badge"))
    }

    func testSourceFootnotesAreStableAcrossSources() {
        let staticViewModel = DiagnosticsViewModel()
        staticViewModel.update(
            summary: RuntimeDiagnosticSummary(dependencies: [], source: .staticPreparation)
        )

        let realViewModel = DiagnosticsViewModel()
        realViewModel.update(
            summary: RuntimeDiagnosticSummary(dependencies: [], source: .realSystemCheck)
        )

        XCTAssertEqual(staticViewModel.sourceNoInstallNote, realViewModel.sourceNoInstallNote)
        XCTAssertEqual(staticViewModel.sourceDxvkMoltenVKLaterNote, realViewModel.sourceDxvkMoltenVKLaterNote)
    }

    func testViewModelDefaultsToStaticSourceWhenSourceMissing() {
        let viewModel = DiagnosticsViewModel()
        viewModel.update(summary: RuntimeDiagnosticSummary(dependencies: []))

        XCTAssertEqual(viewModel.sourceTitle, String(localized: "diagnostics.source.static.title"))
        XCTAssertEqual(viewModel.sourceSubtitle, String(localized: "diagnostics.source.static.subtitle"))
        XCTAssertEqual(viewModel.sourceNote, String(localized: "diagnostics.source.static.note"))
    }

    func testSourceInfoUnaffectedByMissingDependencies() {
        let viewModel = DiagnosticsViewModel()
        viewModel.update(
            summary: RuntimeDiagnosticSummary(
                dependencies: [makeDependency(kind: .wine, status: .missing)],
                source: .staticPreparation
            )
        )

        XCTAssertEqual(viewModel.sourceTitle, String(localized: "diagnostics.source.static.title"))
        XCTAssertEqual(viewModel.sourceBadgeText, String(localized: "diagnostics.source.static.badge"))
    }

    func testManualRealCheckButtonVisibility() {
        let viewModel = DiagnosticsViewModel()
        viewModel.setAllowsManualRealCheck(true)
        viewModel.update(
            summary: RuntimeDiagnosticSummary(dependencies: [], source: .staticPreparation)
        )

        XCTAssertTrue(viewModel.showsManualRealCheckButton)
        XCTAssertFalse(viewModel.showsReturnToPreparationButton)

        viewModel.update(
            summary: RuntimeDiagnosticSummary(dependencies: [], source: .realSystemCheck)
        )

        XCTAssertFalse(viewModel.showsManualRealCheckButton)
        XCTAssertTrue(viewModel.showsReturnToPreparationButton)
    }

    func testManualRealCheckButtonHiddenWhileRunning() {
        let viewModel = DiagnosticsViewModel()
        viewModel.setAllowsManualRealCheck(true)
        viewModel.setRunningRealCheck(true)
        viewModel.update(
            summary: RuntimeDiagnosticSummary(dependencies: [], source: .staticPreparation)
        )

        XCTAssertFalse(viewModel.showsManualRealCheckButton)
        XCTAssertFalse(viewModel.showsReturnToPreparationButton)
    }

    func testManualRealCheckButtonRequiresPolicyAllowance() {
        let viewModel = DiagnosticsViewModel()
        viewModel.update(
            summary: RuntimeDiagnosticSummary(dependencies: [], source: .staticPreparation)
        )

        XCTAssertFalse(viewModel.showsManualRealCheckButton)
    }

    func testLastRealCheckTextOnlyForRealSource() {
        let viewModel = DiagnosticsViewModel()
        let generatedAt = Date(timeIntervalSince1970: 1_700_000_000)

        viewModel.update(
            summary: RuntimeDiagnosticSummary(
                dependencies: [],
                generatedAt: generatedAt,
                source: .realSystemCheck
            )
        )

        XCTAssertNotNil(viewModel.lastRealCheckText)
        XCTAssertTrue(viewModel.lastRealCheckText?.contains("Son gerçek kontrol:") == true)

        viewModel.update(
            summary: RuntimeDiagnosticSummary(
                dependencies: [],
                generatedAt: generatedAt,
                source: .staticPreparation
            )
        )

        XCTAssertNil(viewModel.lastRealCheckText)
    }

    func testDependencyDetailTextOnlyForRealSource() {
        let viewModel = DiagnosticsViewModel()
        let dependency = makeDependency(kind: .wine, status: .ready)
        var detailedDependency = dependency
        detailedDependency.version = "9.0"
        detailedDependency.installPath = "/opt/homebrew/bin/wine"

        viewModel.update(
            summary: RuntimeDiagnosticSummary(
                dependencies: [detailedDependency],
                source: .realSystemCheck
            )
        )

        XCTAssertEqual(
            viewModel.dependencyVersionText(for: detailedDependency),
            String(format: String(localized: "diagnostics.dependency.version"), "9.0")
        )
        XCTAssertEqual(
            viewModel.dependencyInstallPathText(for: detailedDependency),
            String(format: String(localized: "diagnostics.dependency.installPath"), "/opt/homebrew/bin/wine")
        )

        viewModel.update(
            summary: RuntimeDiagnosticSummary(
                dependencies: [detailedDependency],
                source: .staticPreparation
            )
        )

        XCTAssertNil(viewModel.dependencyVersionText(for: detailedDependency))
        XCTAssertNil(viewModel.dependencyInstallPathText(for: detailedDependency))
    }

    func testNextStepSuggestsRealCheckBeforeOtherActions() {
        let viewModel = DiagnosticsViewModel()
        viewModel.setAllowsManualRealCheck(true)
        viewModel.setExperimentalLaunchEnabled(true)
        viewModel.updatePrefixState(makePrefixState(.missing))
        viewModel.update(
            summary: RuntimeDiagnosticSummary(
                dependencies: [makeDependency(kind: .wine, status: .missing)],
                source: .staticPreparation
            ),
            readinessResult: makeReadiness(canLaunch: false),
            experimentalReadinessResult: makeReadiness(canLaunch: false)
        )

        XCTAssertEqual(viewModel.nextAction, .realSystemCheck)
        XCTAssertEqual(viewModel.nextStepButtonTitle, String(localized: "diagnostics.realCheck.button"))
    }

    func testNextStepShowsWinePreparationBeforePrefixOrLaunch() {
        let viewModel = DiagnosticsViewModel()
        viewModel.setAllowsManualRealCheck(true)
        viewModel.setExperimentalLaunchEnabled(true)
        viewModel.updatePrefixState(makePrefixState(.missing))
        viewModel.update(
            summary: RuntimeDiagnosticSummary(
                dependencies: [makeDependency(kind: .wine, status: .missing)],
                source: .realSystemCheck
            ),
            readinessResult: makeReadiness(canLaunch: false),
            experimentalReadinessResult: makeReadiness(canLaunch: false)
        )

        XCTAssertNil(viewModel.nextAction)
        XCTAssertEqual(viewModel.nextStepTitle, String(localized: "diagnostics.nextStep.wine.title"))
        XCTAssertFalse(viewModel.showsNextStepButton)
    }

    func testNextStepSuggestsPrefixWhenWineIsReadyAndPrefixMissing() {
        let viewModel = DiagnosticsViewModel()
        viewModel.setExperimentalLaunchEnabled(true)
        viewModel.updatePrefixState(makePrefixState(.missing))
        viewModel.update(
            summary: RuntimeDiagnosticSummary(
                dependencies: [makeDependency(kind: .wine, status: .ready)],
                source: .realSystemCheck
            ),
            readinessResult: makeReadiness(canLaunch: false),
            experimentalReadinessResult: makeReadiness(canLaunch: false)
        )

        XCTAssertEqual(viewModel.nextAction, .createPrefix)
        XCTAssertEqual(viewModel.nextStepButtonTitle, String(localized: "diagnostics.prefix.createButton"))
    }

    func testNextStepSuggestsExperimentalLaunchWhenReady() {
        let viewModel = DiagnosticsViewModel()
        viewModel.setExperimentalLaunchEnabled(true)
        viewModel.updatePrefixState(makePrefixState(.exists))
        viewModel.update(
            summary: RuntimeDiagnosticSummary(
                dependencies: [makeDependency(kind: .wine, status: .ready)],
                source: .realSystemCheck
            ),
            readinessResult: makeReadiness(canLaunch: false),
            experimentalReadinessResult: makeReadiness(canLaunch: true)
        )

        XCTAssertEqual(viewModel.nextAction, .launchExperimental)
        XCTAssertEqual(viewModel.nextStepButtonTitle, String(localized: "diagnostics.experimentalLaunch.button"))
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

    private func makePrefixState(_ availability: PrefixDirectoryState.Availability) -> PrefixDirectoryState {
        PrefixDirectoryState(
            profileID: "user-game",
            displayName: "User Game",
            relativePath: "Prefixes/user-game",
            absolutePath: "/tmp/MacPlayLauncher/Prefixes/user-game",
            availability: availability
        )
    }

    private func makeReadiness(canLaunch: Bool) -> RunReadinessResult {
        RunReadinessResult(
            status: canLaunch ? .ready : .blocked,
            title: canLaunch ? "ready" : "blocked",
            message: canLaunch ? "ready" : "blocked",
            blockers: canLaunch ? [] : [
                RunReadinessBlocker(
                    id: "blocked",
                    title: "Eksik",
                    message: "Deneysel çalıştırma hazır değil.",
                    severity: .blocking,
                    source: .unknown,
                    suggestedAction: nil,
                    isUserActionable: true
                )
            ],
            canLaunch: canLaunch
        )
    }
}
