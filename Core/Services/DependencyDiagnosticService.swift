import Foundation

protocol DependencyDiagnosticServicing: Sendable {
    func loadSummary(profiles: [GameProfile]) async -> RuntimeDiagnosticSummary
}
