import Foundation

protocol RuntimeDiagnosticProviding: Sendable {
    func diagnose() async -> RuntimeDependency
}
