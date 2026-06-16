import Foundation

enum DiagnosticMode: String, Codable, Sendable, Equatable {
    case staticOnly
    case realReadOnly
}

struct DiagnosticActivationPolicy: Sendable, Equatable {
    let defaultMode: DiagnosticMode
    let allowsRealDiagnostics: Bool
    let requiresExplicitUserAction: Bool

    static let production = DiagnosticActivationPolicy(
        defaultMode: .staticOnly,
        allowsRealDiagnostics: false,
        requiresExplicitUserAction: true
    )

    static let internalRealReadOnly = DiagnosticActivationPolicy(
        defaultMode: .realReadOnly,
        allowsRealDiagnostics: true,
        requiresExplicitUserAction: false
    )
}

enum DiagnosticsSource: String, Codable, Sendable, Equatable {
    case staticPreparation
    case realSystemCheck
}
