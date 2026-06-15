import Foundation
import XCTest
@testable import MacPlayLauncher

final class FakeCommandRunnerTests: XCTestCase {
    func testReturnsDeterministicSuccessResult() async throws {
        let request = commandRequest()
        let expectedResult = CommandResult(exitCode: 0, stdout: "ok", stderr: "", duration: 0.1)
        let runner = FakeCommandRunner(results: [request: .success(expectedResult)])

        let result = try await runner.run(request)

        XCTAssertEqual(result, expectedResult)
    }

    func testReturnsDeterministicTimeoutError() async {
        await assertFakeError(.timedOut)
    }

    func testReturnsDeterministicNonZeroError() async {
        await assertFakeError(.nonZeroExit(42))
    }

    func testReturnsDeterministicLaunchFailure() async {
        await assertFakeError(.launchFailed("fake launch failed"))
    }

    func testReturnsDeterministicOutputTooLargeError() async {
        await assertFakeError(.outputTooLarge)
    }

    func testUnknownRequestReturnsMeaningfulFailure() async {
        let runner = FakeCommandRunner(results: [:])

        do {
            _ = try await runner.run(commandRequest())
            XCTFail("Expected unknown fake request to fail.")
        } catch let error as CommandError {
            XCTAssertEqual(error, .launchFailed("No fake command result registered."))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func assertFakeError(
        _ expectedError: CommandError,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let request = commandRequest()
        let runner = FakeCommandRunner(results: [request: .failure(expectedError)])

        do {
            _ = try await runner.run(request)
            XCTFail("Expected \(expectedError).", file: file, line: line)
        } catch let error as CommandError {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Unexpected error: \(error)", file: file, line: line)
        }
    }

    private func commandRequest() -> CommandRequest {
        CommandRequest(
            executableURL: URL(fileURLWithPath: "/usr/bin/true"),
            arguments: [],
            environment: [:],
            timeoutSeconds: 1,
            purpose: .rosettaCheck
        )
    }
}
