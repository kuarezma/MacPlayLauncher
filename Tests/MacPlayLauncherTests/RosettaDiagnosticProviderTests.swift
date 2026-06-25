import Foundation
@testable import MacPlayLauncher
import XCTest

final class RosettaDiagnosticProviderTests: XCTestCase {
    func testAppleSiliconCommandSuccessReturnsReady() async {
        let request = rosettaRequest()
        let provider = makeProvider(commandResults: [
            request: .success(CommandResult(exitCode: 0, stdout: "", stderr: "", duration: 0.01))
        ])

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .ready)
        XCTAssertEqual(dependency.userFacingDescription, "Rosetta kullanılabilir görünüyor.")
        XCTAssertNil(dependency.suggestedAction)
    }

    func testAppleSiliconTimeoutReturnsUnknown() async {
        let provider = makeProvider(error: .timedOut)

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .unknown)
        XCTAssertEqual(dependency.userFacingDescription, "Rosetta durumu doğrulanamadı.")
    }

    func testAppleSiliconLaunchFailedReturnsUnknown() async {
        let provider = makeProvider(error: .launchFailed("failed"))

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .unknown)
    }

    func testAppleSiliconExecutableNotAllowedReturnsUnknown() async {
        let provider = makeProvider(error: .executableNotAllowed(URL(fileURLWithPath: "/usr/bin/arch")))

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .unknown)
    }

    func testAppleSiliconOutputTooLargeReturnsUnknown() async {
        let provider = makeProvider(error: .outputTooLarge)

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .unknown)
    }

    func testAppleSiliconNonZeroReturnsMissing() async {
        let provider = makeProvider(error: .nonZeroExit(1))

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .missing)
        XCTAssertEqual(dependency.missingReason, "Rosetta kurulu görünmüyor.")
        XCTAssertEqual(dependency.suggestedAction, "Rosetta gerekiyorsa Apple’ın resmi kurulum yönergelerini izleyin.")
    }

    func testIntelArchitectureReturnsNotRequiredWithoutRunningCommand() async {
        let provider = RosettaDiagnosticProvider(
            commandRunner: FakeCommandRunner(results: [:]),
            architectureProvider: FakeSystemArchitectureProvider(architecture: .intel),
            timeoutSeconds: 2
        )

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .notRequired)
        XCTAssertEqual(dependency.userFacingDescription, "Bu cihazda Rosetta gerekli görünmüyor.")
    }

    func testUnknownArchitectureReturnsUnknownWithoutRunningCommand() async {
        let provider = RosettaDiagnosticProvider(
            commandRunner: FakeCommandRunner(results: [:]),
            architectureProvider: FakeSystemArchitectureProvider(architecture: .unknown),
            timeoutSeconds: 2
        )

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .unknown)
        XCTAssertEqual(dependency.userFacingDescription, "Rosetta durumu doğrulanamadı.")
    }

    func testUserFacingFieldsArePassive() async {
        let provider = makeProvider(error: .nonZeroExit(1))

        let dependency = await provider.diagnose()

        XCTAssertFalse(dependency.userFacingDescription.isEmpty)
        XCTAssertFalse(dependency.suggestedAction?.isEmpty ?? true)
        XCTAssertFalse(dependency.suggestedAction?.contains("softwareupdate") ?? false)
    }

    private func makeProvider(error: CommandError) -> RosettaDiagnosticProvider {
        let request = rosettaRequest()
        return makeProvider(commandResults: [request: .failure(error)])
    }

    private func makeProvider(
        commandResults: [CommandRequest: Result<CommandResult, CommandError>]
    ) -> RosettaDiagnosticProvider {
        RosettaDiagnosticProvider(
            commandRunner: FakeCommandRunner(results: commandResults),
            architectureProvider: FakeSystemArchitectureProvider(architecture: .appleSilicon),
            timeoutSeconds: 2
        )
    }

    private func rosettaRequest() -> CommandRequest {
        CommandRequest(
            executableURL: URL(fileURLWithPath: "/usr/bin/arch"),
            arguments: ["-x86_64", "/usr/bin/true"],
            environment: [:],
            timeoutSeconds: 2,
            purpose: .rosettaCheck
        )
    }
}

private struct FakeSystemArchitectureProvider: SystemArchitectureProviding {
    let architecture: SystemArchitecture
}
