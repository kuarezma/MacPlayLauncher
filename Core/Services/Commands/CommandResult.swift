import Foundation

struct CommandResult: Equatable, Sendable {
    let exitCode: Int32
    let stdout: String
    let stderr: String
    let duration: TimeInterval
}

enum CommandError: Error, Equatable, Sendable {
    case executableNotAllowed(URL)
    case timedOut
    case nonZeroExit(Int32)
    case launchFailed(String)
    case outputTooLarge
}
