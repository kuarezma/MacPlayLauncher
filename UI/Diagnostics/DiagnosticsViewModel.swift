import Foundation
import SwiftUI

@MainActor
@Observable
final class DiagnosticsViewModel {
    private(set) var summary: RuntimeDiagnosticSummary?

    var dependencies: [RuntimeDependency] {
        summary?.dependencies ?? []
    }

    var overallTitle: String {
        switch summary?.overallStatus {
        case .ready:
            return String(localized: "diagnostics.overall.ready")
        case .hasMissingDependencies:
            return String(localized: "diagnostics.overall.missing")
        case .unknown:
            return String(localized: "diagnostics.overall.unknown")
        case .none:
            return String(localized: "diagnostics.overall.loading")
        }
    }

    var overallDescription: String {
        switch summary?.overallStatus {
        case .ready:
            return String(localized: "diagnostics.overall.ready.description")
        case .hasMissingDependencies:
            return String(localized: "diagnostics.overall.missing.description")
        case .unknown:
            return String(localized: "diagnostics.overall.unknown.description")
        case .none:
            return String(localized: "diagnostics.overall.loading.description")
        }
    }

    func update(summary: RuntimeDiagnosticSummary) {
        self.summary = summary
    }

    func badgeText(for status: RuntimeDependencyStatus) -> String {
        switch status {
        case .ready:
            return String(localized: "diagnostics.status.ready")
        case .missing:
            return String(localized: "diagnostics.status.missing")
        case .unknown:
            return String(localized: "diagnostics.status.unknown")
        case .notRequired:
            return String(localized: "diagnostics.status.notRequired")
        case .unsupported:
            return String(localized: "diagnostics.status.unsupported")
        }
    }

    func badgeColor(for status: RuntimeDependencyStatus) -> Color {
        switch status {
        case .ready, .notRequired:
            return .green
        case .missing, .unsupported:
            return .red
        case .unknown:
            return .orange
        }
    }
}
