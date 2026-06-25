import Foundation

final class FakeCommandRunner: CommandRunning, @unchecked Sendable {
    let results: [CommandRequest: Result<CommandResult, CommandError>]
    private let lock = NSLock()
    private var recordedRequests: [CommandRequest] = []

    init(results: [CommandRequest: Result<CommandResult, CommandError>]) {
        self.results = results
    }

    var requests: [CommandRequest] {
        lock.withLock {
            recordedRequests
        }
    }

    func run(_ request: CommandRequest) async throws -> CommandResult {
        lock.withLock {
            recordedRequests.append(request)
        }

        guard let result = results[request] else {
            throw CommandError.launchFailed("No fake command result registered.")
        }

        return try result.get()
    }
}
