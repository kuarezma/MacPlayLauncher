import SwiftUI

@MainActor
extension DiagnosticsViewModel {
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

    func readinessBadgeText(for status: RunReadinessStatus) -> String {
        switch status {
        case .ready:
            return String(localized: "readiness.ready.title")
        case .blocked:
            return String(localized: "readiness.blocked.title")
        case .unknown:
            return String(localized: "readiness.unknown.title")
        case .unsupported:
            return String(localized: "readiness.unsupported.title")
        }
    }

    func readinessBadgeColor(for status: RunReadinessStatus) -> Color {
        switch status {
        case .ready:
            return .green
        case .blocked, .unsupported:
            return .red
        case .unknown:
            return .orange
        }
    }

    func severityText(for severity: RunReadinessSeverity) -> String {
        switch severity {
        case .info:
            return String(localized: "readiness.severity.info")
        case .warning:
            return String(localized: "readiness.severity.warning")
        case .blocking:
            return String(localized: "readiness.severity.blocking")
        }
    }

    func severityColor(for severity: RunReadinessSeverity) -> Color {
        switch severity {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .blocking:
            return .red
        }
    }
}
