import Foundation

protocol RunReadinessEvaluating: Sendable {
    func evaluate(
        profiles: [GameProfile],
        diagnosticSummary: RuntimeDiagnosticSummary
    ) -> RunReadinessResult
}
