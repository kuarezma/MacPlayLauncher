import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class DiagnosticsViewModel {
    private(set) var summary: RuntimeDiagnosticSummary?
    private(set) var readinessResult: RunReadinessResult?
    private(set) var isRunningRealCheck = false
    private(set) var allowsManualRealCheck = false

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
        return String(format: String(localized: "diagnostics.realCheck.lastChecked"), formattedDate)
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

