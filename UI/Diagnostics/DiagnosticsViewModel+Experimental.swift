import Foundation

@MainActor
extension DiagnosticsViewModel {
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
}
