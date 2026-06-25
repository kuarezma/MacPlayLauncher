import Foundation
import Observation
import SwiftUI

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

    func setAllowsManualRealCheck(_ value: Bool) {
        allowsManualRealCheck = value
    }

    func setRunningRealCheck(_ value: Bool) {
        isRunningRealCheck = value
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

    func updatePrefixState(_ state: PrefixDirectoryState?) {
        prefixState = state
    }

    func setCreatingPrefix(_ isCreating: Bool) {
        isCreatingPrefix = isCreating
    }

    func setPrefixFeedbackMessage(_ message: String?) {
        prefixFeedbackMessage = message
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
}
