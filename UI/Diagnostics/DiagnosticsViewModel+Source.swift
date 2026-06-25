import Foundation
import SwiftUI

@MainActor
extension DiagnosticsViewModel {
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
}
