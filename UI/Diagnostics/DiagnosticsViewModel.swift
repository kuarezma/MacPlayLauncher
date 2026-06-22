import Foundation
import SwiftUI
import Observation

enum DiagnosticsNextAction: Equatable, Sendable {
    case realSystemCheck
    case createPrefix
    case launchExperimental
}

@MainActor
@Observable
final class DiagnosticsViewModel {
    private(set) var summary: RuntimeDiagnosticSummary?
    private(set) var readinessResult: RunReadinessResult?
    private(set) var isRunningRealCheck = false
    private(set) var allowsManualRealCheck = false
    private(set) var prefixState: PrefixDirectoryState?
    private(set) var isCreatingPrefix = false
    private(set) var prefixFeedbackMessage: String?
    private(set) var experimentalReadinessResult: RunReadinessResult?
    private(set) var isExperimentalLaunchEnabled = false
    private(set) var isLaunchingExperimental = false
    private(set) var experimentalLaunchFeedbackMessage: String?

    var nextStepTitle: String {
        switch nextAction {
        case .realSystemCheck:
            return String(localized: "diagnostics.nextStep.realCheck.title")
        case .createPrefix:
            return String(localized: "diagnostics.nextStep.prefix.title")
        case .launchExperimental:
            return String(localized: "diagnostics.nextStep.experimental.title")
        case .none:
            if summary == nil {
                return String(localized: "diagnostics.nextStep.loading.title")
            }
            if needsWinePreparation {
                return String(localized: "diagnostics.nextStep.wine.title")
            }
            return String(localized: "diagnostics.nextStep.review.title")
        }
    }

    var nextStepMessage: String {
        if summary == nil {
            return String(localized: "diagnostics.nextStep.loading.message")
        }

        switch nextAction {
        case .realSystemCheck:
            return String(localized: "diagnostics.nextStep.realCheck.message")
        case .createPrefix:
            return String(localized: "diagnostics.nextStep.prefix.message")
        case .launchExperimental:
            return String(localized: "diagnostics.nextStep.experimental.message")
        case .none:
            if needsWinePreparation {
                return String(localized: "diagnostics.nextStep.wine.message")
            }
            return firstExperimentalBlockerMessage
                ?? String(localized: "diagnostics.nextStep.review.message")
        }
    }

    var nextAction: DiagnosticsNextAction? {
        guard let summary else {
            return nil
        }

        if summary.source != .realSystemCheck, allowsManualRealCheck {
            return .realSystemCheck
        }

        if needsWinePreparation {
            return nil
        }

        if prefixState?.availability == .missing {
            return .createPrefix
        }

        if isExperimentalLaunchEnabled, experimentalReadinessResult?.canLaunch == true {
            return .launchExperimental
        }

        return nil
    }

    var nextStepButtonTitle: String? {
        switch nextAction {
        case .realSystemCheck:
            return realCheckButtonTitle
        case .createPrefix:
            return prefixCreateButtonTitle
        case .launchExperimental:
            return experimentalLaunchButtonTitle
        case .none:
            return nil
        }
    }

    var showsNextStepButton: Bool {
        guard let nextAction else {
            return false
        }

        switch nextAction {
        case .realSystemCheck:
            return !isRunningRealCheck
        case .createPrefix:
            return !isCreatingPrefix
        case .launchExperimental:
            return !isLaunchingExperimental
        }
    }

    var experimentalLaunchTitle: String {
        String(localized: "diagnostics.experimentalLaunch.title")
    }

    var experimentalLaunchSubtitle: String {
        String(localized: "diagnostics.experimentalLaunch.subtitle")
    }

    var experimentalLaunchButtonTitle: String {
        String(localized: "diagnostics.experimentalLaunch.button")
    }

    var experimentalLaunchLoadingTitle: String {
        String(localized: "diagnostics.experimentalLaunch.loading")
    }

    var experimentalLaunchDisabledNote: String {
        String(localized: "diagnostics.experimentalLaunch.disabledNote")
    }

    var showsExperimentalLaunchButton: Bool {
        isExperimentalLaunchEnabled
            && experimentalReadinessResult?.canLaunch == true
            && !isLaunchingExperimental
    }

    var experimentalReadinessTitle: String {
        experimentalReadinessResult?.title ?? String(localized: "readiness.unknown.title")
    }

    var experimentalReadinessMessage: String {
        experimentalReadinessResult?.message ?? String(localized: "readiness.unknown.message")
    }

    var experimentalReadinessBlockers: [RunReadinessBlocker] {
        experimentalReadinessResult?.blockers ?? []
    }

    private var firstExperimentalBlockerMessage: String? {
        experimentalReadinessResult?.blockers.first?.message
    }

    private var needsWinePreparation: Bool {
        guard summary?.source == .realSystemCheck,
              let wine = summary?.dependencies.first(where: { $0.kind == .wine }) else {
            return false
        }

        return wine.status != .ready
    }

    func setExperimentalLaunchEnabled(_ value: Bool) {
        isExperimentalLaunchEnabled = value
    }

    func setLaunchingExperimental(_ value: Bool) {
        isLaunchingExperimental = value
    }

    func setExperimentalLaunchFeedbackMessage(_ message: String?) {
        experimentalLaunchFeedbackMessage = message
    }

    var prefixTitle: String {
        String(localized: "diagnostics.prefix.title")
    }

    var prefixSubtitle: String {
        String(localized: "diagnostics.prefix.subtitle")
    }

    var prefixWineBootstrapNote: String {
        String(localized: "diagnostics.prefix.wineBootstrapNote")
    }

    var prefixCreateButtonTitle: String {
        String(localized: "diagnostics.prefix.createButton")
    }

    var prefixCreatingTitle: String {
        String(localized: "diagnostics.prefix.creating")
    }

    var prefixNoProfileText: String {
        String(localized: "diagnostics.prefix.noProfile")
    }

    func profileLabel(for state: PrefixDirectoryState) -> String {
        String(format: String(localized: "diagnostics.prefix.profile"), state.displayName)
    }

    func relativePathLabel(for state: PrefixDirectoryState) -> String {
        String(format: String(localized: "diagnostics.prefix.relativePath"), state.relativePath)
    }

    func absolutePathLabel(for state: PrefixDirectoryState) -> String {
        String(format: String(localized: "diagnostics.prefix.absolutePath"), state.absolutePath)
    }

    func prefixStatusText(for availability: PrefixDirectoryState.Availability) -> String {
        switch availability {
        case .missing:
            return String(localized: "diagnostics.prefix.status.missing")
        case .exists:
            return String(localized: "diagnostics.prefix.status.exists")
        }
    }

    var showsPrefixCreateButton: Bool {
        guard let prefixState, !isCreatingPrefix else {
            return false
        }

        return prefixState.availability == .missing
    }

    func updatePrefixState(_ state: PrefixDirectoryState?) {
        prefixState = state
    }

    func setCreatingPrefix(_ isCreating: Bool) {
        isCreatingPrefix = isCreating
    }

    func setPrefixFeedbackMessage(_ message: String?) {
        prefixFeedbackMessage = message
    }

    var dependencies: [RuntimeDependency] {
        summary?.dependencies ?? []
    }

    var readinessTitle: String {
        readinessResult?.title ?? String(localized: "readiness.unknown.title")
    }

    var readinessMessage: String {
        readinessResult?.message ?? String(localized: "readiness.unknown.message")
    }

    var readinessBlockers: [RunReadinessBlocker] {
        readinessResult?.blockers ?? []
    }

    var launchNotImplementedText: String {
        String(localized: "readiness.launchNotImplemented")
    }

    var noLaunchThisSprintText: String {
        String(localized: "readiness.noLaunchThisSprint")
    }

    var overallTitle: String {
        switch summary?.overallStatus {
        case .ready:
            return String(localized: "diagnostics.overall.ready")
        case .hasMissingDependencies:
            return String(localized: "diagnostics.overall.missing")
        case .unknown:
            return String(localized: "diagnostics.overall.unknown")
        case .none:
            return String(localized: "diagnostics.overall.loading")
        }
    }

    var overallDescription: String {
        switch summary?.overallStatus {
        case .ready:
            return String(localized: "diagnostics.overall.ready.description")
        case .hasMissingDependencies:
            return String(localized: "diagnostics.overall.missing.description")
        case .unknown:
            return String(localized: "diagnostics.overall.unknown.description")
        case .none:
            return String(localized: "diagnostics.overall.loading.description")
        }
    }

    var sourceTitle: String {
        switch summary?.source {
        case .realSystemCheck:
            return String(localized: "diagnostics.source.real.title")
        case .staticPreparation, .none:
            return String(localized: "diagnostics.source.static.title")
        }
    }

    var sourceSubtitle: String {
        switch summary?.source {
        case .realSystemCheck:
            return String(localized: "diagnostics.source.real.subtitle")
        case .staticPreparation, .none:
            return String(localized: "diagnostics.source.static.subtitle")
        }
    }

    var sourceNote: String? {
        switch summary?.source {
        case .realSystemCheck:
            return nil
        case .staticPreparation, .none:
            return String(localized: "diagnostics.source.static.note")
        }
    }

    var realCheckButtonTitle: String {
        String(localized: "diagnostics.realCheck.button")
    }

    var realCheckLoadingTitle: String {
        String(localized: "diagnostics.realCheck.loading")
    }

    var returnToPreparationButtonTitle: String {
        String(localized: "diagnostics.realCheck.returnToPreparation")
    }

    var showsManualRealCheckButton: Bool {
        allowsManualRealCheck
            && summary?.source != .realSystemCheck
            && !isRunningRealCheck
    }

    var showsReturnToPreparationButton: Bool {
        allowsManualRealCheck
            && summary?.source == .realSystemCheck
            && !isRunningRealCheck
    }

    var sourceBadgeText: String {
        switch summary?.source {
        case .realSystemCheck:
            return String(localized: "diagnostics.source.real.badge")
        case .staticPreparation, .none:
            return String(localized: "diagnostics.source.static.badge")
        }
    }

    var sourceNoInstallNote: String {
        String(localized: "diagnostics.source.noInstall")
    }

    var sourceDxvkMoltenVKLaterNote: String {
        String(localized: "diagnostics.source.dxvkMoltenVKLater")
    }

    var lastRealCheckText: String? {
        guard summary?.source == .realSystemCheck, let generatedAt = summary?.generatedAt else {
            return nil
        }

        return formattedLastRealCheckText(generatedAt: generatedAt)
    }

    func dependencyVersionText(for dependency: RuntimeDependency) -> String? {
        guard showsRealCheckDependencyDetails, let version = dependency.version else {
            return nil
        }

        return String(format: String(localized: "diagnostics.dependency.version"), version)
    }

    func dependencyInstallPathText(for dependency: RuntimeDependency) -> String? {
        guard showsRealCheckDependencyDetails, let installPath = dependency.installPath else {
            return nil
        }

        return String(format: String(localized: "diagnostics.dependency.installPath"), installPath)
    }

    func formattedLastRealCheckText(generatedAt: Date) -> String {
        let formattedDate = generatedAt.formatted(
            .dateTime
                .day()
                .month(.wide)
                .year()
                .hour()
                .minute()
                .locale(Locale(identifier: "tr_TR"))
        )
        return String(
            format: LocalizedFallback.text(
                "diagnostics.realCheck.lastChecked",
                fallback: "Son gerçek kontrol: %@"
            ),
            formattedDate
        )
    }

    private var showsRealCheckDependencyDetails: Bool {
        summary?.source == .realSystemCheck
    }

    func setAllowsManualRealCheck(_ value: Bool) {
        allowsManualRealCheck = value
    }

    func setRunningRealCheck(_ value: Bool) {
        isRunningRealCheck = value
    }

    func update(summary: RuntimeDiagnosticSummary) {
        self.summary = summary
    }

    func update(summary: RuntimeDiagnosticSummary, readinessResult: RunReadinessResult) {
        self.summary = summary
        self.readinessResult = readinessResult
    }

    func update(
        summary: RuntimeDiagnosticSummary,
        readinessResult: RunReadinessResult,
        experimentalReadinessResult: RunReadinessResult
    ) {
        self.summary = summary
        self.readinessResult = readinessResult
        self.experimentalReadinessResult = experimentalReadinessResult
    }

    func badgeText(for status: RuntimeDependencyStatus) -> String {
        switch status {
        case .ready:
            return String(localized: "diagnostics.status.ready")
        case .missing:
            return String(localized: "diagnostics.status.missing")
        case .unknown:
            return String(localized: "diagnostics.status.unknown")
        case .notRequired:
            return String(localized: "diagnostics.status.notRequired")
        case .unsupported:
            return String(localized: "diagnostics.status.unsupported")
        }
    }

    func badgeColor(for status: RuntimeDependencyStatus) -> Color {
        switch status {
        case .ready, .notRequired:
            return .green
        case .missing, .unsupported:
            return .red
        case .unknown:
            return .orange
        }
    }

    func readinessBadgeText(for status: RunReadinessStatus) -> String {
        switch status {
        case .ready:
            return String(localized: "readiness.ready.title")
        case .blocked:
            return String(localized: "readiness.blocked.title")
        case .unknown:
            return String(localized: "readiness.unknown.title")
        case .unsupported:
            return String(localized: "readiness.unsupported.title")
        }
    }

    func readinessBadgeColor(for status: RunReadinessStatus) -> Color {
        switch status {
        case .ready:
            return .green
        case .blocked, .unsupported:
            return .red
        case .unknown:
            return .orange
        }
    }

    func severityText(for severity: RunReadinessSeverity) -> String {
        switch severity {
        case .info:
            return String(localized: "readiness.severity.info")
        case .warning:
            return String(localized: "readiness.severity.warning")
        case .blocking:
            return String(localized: "readiness.severity.blocking")
        }
    }

    func severityColor(for severity: RunReadinessSeverity) -> Color {
        switch severity {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .blocking:
            return .red
        }
    }
}
