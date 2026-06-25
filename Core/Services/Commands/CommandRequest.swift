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
    case displayResolutionList
    case displayResolutionSet
    case crossOverInstall
    case crossOverOpen
    case bottleCreate
    case steamSetup
    case wineSteamLaunch
    case processLookup
    case processKill
}

struct CommandRequest: Equatable, Hashable, Sendable {
    let executableURL: URL
    let arguments: [String]
    let environment: [String: String]
    let timeoutSeconds: TimeInterval
    let purpose: CommandPurpose
}
