import Foundation

protocol DependencyDiagnosticServicing: Sendable {
    func loadSummary(profiles: [GameProfile]) async -> RuntimeDiagnosticSummary
}

protocol ModeAwareDependencyDiagnosticServicing: DependencyDiagnosticServicing {
    func loadSummary(profiles: [GameProfile], mode: DiagnosticMode) async -> RuntimeDiagnosticSummary
}
