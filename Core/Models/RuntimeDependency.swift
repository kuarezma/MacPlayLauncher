import Foundation

enum RuntimeDependencyKind: String, Codable, CaseIterable, Sendable {
    case rosetta
    case wine
    case dxvk
    case moltenVK
    case gameProfile
}

enum RuntimeDependencyStatus: String, Codable, Sendable {
    case ready
    case missing
    case unknown
    case notRequired
    case unsupported
}

struct RuntimeSetupGuide: Codable, Equatable, Sendable {
    var title: String
    var steps: [String]
}

struct RuntimeDependency: Codable, Equatable, Identifiable, Sendable {
    var id: RuntimeDependencyKind { kind }

    var displayName: String
    var kind: RuntimeDependencyKind
    var status: RuntimeDependencyStatus
    var version: String?
    var installPath: String?
    var userFacingDescription: String
    var missingReason: String?
    var suggestedAction: String?
    var setupGuide: RuntimeSetupGuide?
}
