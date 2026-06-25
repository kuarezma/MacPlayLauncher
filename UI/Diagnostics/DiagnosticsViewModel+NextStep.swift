import Foundation

@MainActor
extension DiagnosticsViewModel {
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

    fileprivate var firstExperimentalBlockerMessage: String? {
        experimentalReadinessResult?.blockers.first?.message
    }

    fileprivate var needsWinePreparation: Bool {
        guard summary?.source == .realSystemCheck,
              let wine = summary?.dependencies.first(where: { $0.kind == .wine }) else {
            return false
        }

        return wine.status != .ready
    }
}
