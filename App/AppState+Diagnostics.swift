import Foundation

@MainActor
extension AppState {
    var canRunManualRealDiagnosticCheck: Bool {
        guard let policy = environment.diagnosticActivationPolicy else {
            return false
        }

        return policy.allowsRealDiagnostics && policy.requiresExplicitUserAction
    }

    func loadRuntimeDiagnosticSummary(mode: DiagnosticMode = .staticOnly) async -> RuntimeDiagnosticSummary {
        if let modeAware = environment.dependencyDiagnosticService as? any ModeAwareDependencyDiagnosticServicing {
            return await modeAware.loadSummary(profiles: profiles, mode: mode)
        }

        return await environment.dependencyDiagnosticService.loadSummary(profiles: profiles)
    }

    func evaluateRunReadiness(diagnosticSummary: RuntimeDiagnosticSummary) -> RunReadinessResult {
        environment.runReadinessEvaluator.evaluate(
            profiles: profiles,
            diagnosticSummary: diagnosticSummary
        )
    }

    func evaluateExperimentalRunReadiness(diagnosticSummary: RuntimeDiagnosticSummary) -> RunReadinessResult {
        environment.experimentalRunReadinessEvaluator.evaluate(
            profiles: profiles,
            diagnosticSummary: diagnosticSummary
        )
    }

    func restoreCachedDiagnosticsIfAvailable() -> (
        summary: RuntimeDiagnosticSummary,
        readinessResult: RunReadinessResult
    )? {
        guard diagnosticsDisplayMode == .realReadOnly,
              let summary = cachedDiagnosticSummary,
              let readinessResult = cachedReadinessResult,
              summary.source == .realSystemCheck else {
            return nil
        }

        return (summary, readinessResult)
    }

    func storeDiagnosticsSession(
        mode: DiagnosticMode,
        summary: RuntimeDiagnosticSummary,
        readinessResult: RunReadinessResult
    ) {
        diagnosticsDisplayMode = mode
        cachedDiagnosticSummary = summary
        cachedReadinessResult = readinessResult
    }

    func resetDiagnosticsSessionToStaticPreparation() {
        diagnosticsDisplayMode = .staticOnly
        cachedDiagnosticSummary = nil
        cachedReadinessResult = nil
    }

    func libraryReadinessResult() async -> RunReadinessResult {
        if let cached = restoreCachedDiagnosticsIfAvailable() {
            return cached.readinessResult
        }

        let summary = await loadRuntimeDiagnosticSummary(mode: .staticOnly)
        return evaluateRunReadiness(diagnosticSummary: summary)
    }

    var diagnosticsSessionSourceLabel: String {
        switch cachedDiagnosticSummary?.source {
        case .realSystemCheck:
            return String(localized: "diagnostics.source.real.title")
        case .staticPreparation, .none:
            return String(localized: "diagnostics.source.static.title")
        }
    }
}
