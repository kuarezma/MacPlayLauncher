import Foundation

struct FakeCommandRunner: CommandRunning {
    var results: [CommandRequest: Result<CommandResult, CommandError>]

    init(results: [CommandRequest: Result<CommandResult, CommandError>]) {
        self.results = results
    }

    func run(_ request: CommandRequest) async throws -> CommandResult {
        guard let result = results[request] else {
            throw CommandError.launchFailed("No fake command result registered.")
        }

        return try result.get()
    }
}
