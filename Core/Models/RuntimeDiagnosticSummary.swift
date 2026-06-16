import Foundation

enum RuntimeDiagnosticOverallStatus: String, Codable, Sendable {
    case ready
    case hasMissingDependencies
    case unknown
}

struct RuntimeDiagnosticSummary: Codable, Equatable, Sendable {
    var dependencies: [RuntimeDependency]
    var overallStatus: RuntimeDiagnosticOverallStatus
    var generatedAt: Date
    var notes: [String]
    var source: DiagnosticsSource?

    init(
        dependencies: [RuntimeDependency],
        generatedAt: Date = Date(),
        notes: [String] = [],
        source: DiagnosticsSource? = nil
    ) {
        self.dependencies = dependencies
        self.overallStatus = Self.makeOverallStatus(for: dependencies)
        self.generatedAt = generatedAt
        self.notes = notes
        self.source = source
    }

    static func makeOverallStatus(for dependencies: [RuntimeDependency]) -> RuntimeDiagnosticOverallStatus {
        if dependencies.contains(where: { $0.status == .missing || $0.status == .unsupported }) {
            return .hasMissingDependencies
        }

        if dependencies.contains(where: { $0.status == .unknown }) {
            return .unknown
        }

        return .ready
    }
}
