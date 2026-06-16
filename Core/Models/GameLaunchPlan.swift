import Foundation

struct GameLaunchPlan: Equatable, Sendable {
    let profileID: String
    let wineURL: URL
    let arguments: [String]
    let environment: [String: String]
    let executableURL: URL
    let workingDirectoryURL: URL
}

struct GameLaunchResult: Equatable, Sendable {
    let profileID: String
    let processIdentifier: Int32
}
