import Foundation
import XCTest
@testable import MacPlayLauncher

final class CommandRunnerTests: XCTestCase {
    func testAllowedExecutableRuns() async throws {
        let request = commandRequest(executablePath: "/usr/bin/true")
        let runner = ProcessCommandRunner(allowedExecutableURLs: [request.executableURL])

        let result = try await runner.run(request)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.stdout, "")
        XCTAssertEqual(result.stderr, "")
    }

    func testNotAllowedExecutableIsRejected() async {
        let request = commandRequest(executablePath: "/usr/bin/env")
        let runner = ProcessCommandRunner(allowedExecutableURLs: [URL(fileURLWithPath: "/usr/bin/true")])

        await assertCommandError(.executableNotAllowed(request.executableURL)) {
            try await runner.run(request)
        }
    }

    func testShellExecutablesAreRejected() async {
        for shellPath in ["/bin/sh", "/bin/zsh", "/bin/bash"] {
            let request = commandRequest(executablePath: shellPath)
            let runner = ProcessCommandRunner(allowedExecutableURLs: [request.executableURL])

            await assertCommandError(.executableNotAllowed(request.executableURL)) {
                try await runner.run(request)
            }
        }
    }

    func testDashCArgumentIsRejected() async {
        let request = commandRequest(executablePath: "/usr/bin/true", arguments: ["-c"])
        let runner = ProcessCommandRunner(allowedExecutableURLs: [request.executableURL])

        await assertCommandError(.executableNotAllowed(request.executableURL)) {
            try await runner.run(request)
        }
    }

    func testNonZeroExitThrows() async {
        let request = commandRequest(executablePath: "/usr/bin/false")
        let runner = ProcessCommandRunner(allowedExecutableURLs: [request.executableURL])

        await assertCommandError(.nonZeroExit(1)) {
            try await runner.run(request)
        }
    }

    func testStdoutIsCapturedWithoutShell() async throws {
        let request = commandRequest(
            executablePath: "/bin/echo",
            arguments: ["MacPlay"]
        )
        let runner = ProcessCommandRunner(allowedExecutableURLs: [request.executableURL])

        let result = try await runner.run(request)

        XCTAssertEqual(result.exitCode, 0)
        XCTAssertEqual(result.stdout, "MacPlay\n")
        XCTAssertEqual(result.stderr, "")
    }

    func testTimeoutThrows() async {
        let request = commandRequest(
            executablePath: "/bin/sleep",
            arguments: ["2"],
            timeoutSeconds: 0.05
        )
        let runner = ProcessCommandRunner(allowedExecutableURLs: [request.executableURL])

        await assertCommandError(.timedOut) {
            try await runner.run(request)
        }
    }

    func testOutputLimitThrows() async {
        let request = commandRequest(executablePath: "/usr/bin/yes", timeoutSeconds: 2)
        let runner = ProcessCommandRunner(
            allowedExecutableURLs: [request.executableURL],
            outputLimitBytes: 128
        )

        await assertCommandError(.outputTooLarge) {
            try await runner.run(request)
        }
    }

    private func commandRequest(
        executablePath: String,
        arguments: [String] = [],
        timeoutSeconds: TimeInterval = 1
    ) -> CommandRequest {
        CommandRequest(
            executableURL: URL(fileURLWithPath: executablePath),
            arguments: arguments,
            environment: [:],
            timeoutSeconds: timeoutSeconds,
            purpose: .rosettaCheck
        )
    }

    private func assertCommandError(
        _ expectedError: CommandError,
        operation: () async throws -> CommandResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected \(expectedError).", file: file, line: line)
        } catch let error as CommandError {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }
}
