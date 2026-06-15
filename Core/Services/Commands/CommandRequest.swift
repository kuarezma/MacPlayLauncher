import Foundation

enum CommandPurpose: Equatable, Hashable, Sendable {
    case rosettaCheck
    case wineVersionCheck
    case dxvkFileCheck
    case moltenVKFileCheck
}

struct CommandRequest: Equatable, Hashable, Sendable {
    let executableURL: URL
    let arguments: [String]
    let environment: [String: String]
    let timeoutSeconds: TimeInterval
    let purpose: CommandPurpose
}
