import Foundation

enum CommandPurpose: Equatable, Hashable, Sendable {
    case rosettaCheck
    case wineVersionCheck
    case dxvkFileCheck
    case moltenVKFileCheck
    case gameLaunch
    case rosettaInstall
    case homebrewInstallPrompt
    case displayplacerInstall
    case crossOverInstall
    case crossOverOpen
    case bottleCreate
    case steamSetup
}

struct CommandRequest: Equatable, Hashable, Sendable {
    let executableURL: URL
    let arguments: [String]
    let environment: [String: String]
    let timeoutSeconds: TimeInterval
    let purpose: CommandPurpose
}
