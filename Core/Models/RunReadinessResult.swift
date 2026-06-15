import Foundation

enum RunReadinessStatus: Equatable, Sendable {
    case ready
    case blocked
    case unknown
    case unsupported
}

enum RunReadinessSeverity: Equatable, Sendable {
    case info
    case warning
    case blocking
}

enum RunReadinessBlockerSource: Equatable, Sendable {
    case gameProfile
    case runtimeDependency
    case unsupportedEnvironment
    case unknown
}

struct RunReadinessBlocker: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let message: String
    let severity: RunReadinessSeverity
    let source: RunReadinessBlockerSource
    let suggestedAction: String?
    let isUserActionable: Bool
}

struct RunReadinessResult: Equatable, Sendable {
    let status: RunReadinessStatus
    let title: String
    let message: String
    let blockers: [RunReadinessBlocker]
    let canLaunch: Bool
}
