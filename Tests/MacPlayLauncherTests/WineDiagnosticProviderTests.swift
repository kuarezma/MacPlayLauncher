import Foundation
@testable import MacPlayLauncher
import XCTest

final class WineDiagnosticProviderTests: XCTestCase {
    func testHomebrewWineVersionSuccessReturnsReadyWithVersion() async {
        let wineURL = URL(fileURLWithPath: "/opt/homebrew/bin/wine")
        let provider = makeProvider(
            existingURLs: [wineURL],
            executableURLs: [wineURL],
            commandResults: [
                wineRequest(wineURL): .success(
                    CommandResult(exitCode: 0, stdout: "wine-9.0\n", stderr: "", duration: 0.01)
                )
            ]
        )

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .ready)
        XCTAssertEqual(dependency.version, "9.0")
        XCTAssertEqual(dependency.installPath, wineURL.path)
        XCTAssertEqual(dependency.userFacingDescription, "Wine bulundu ve sürüm bilgisi okunabildi.")
    }

    func testUsrLocalWineFallbackReturnsReady() async {
        let wineURL = URL(fileURLWithPath: "/usr/local/bin/wine")
        let provider = makeProvider(
            existingURLs: [wineURL],
            executableURLs: [wineURL],
            commandResults: [
                wineRequest(wineURL): .success(
                    CommandResult(exitCode: 0, stdout: "wine-8.0.2\n", stderr: "", duration: 0.01)
                )
            ]
        )

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .ready)
        XCTAssertEqual(dependency.version, "8.0.2")
        XCTAssertEqual(dependency.installPath, wineURL.path)
    }

    func testHomebrewWineTakesPriorityWhenBothPathsExist() async {
        let homebrewURL = URL(fileURLWithPath: "/opt/homebrew/bin/wine")
        let usrLocalURL = URL(fileURLWithPath: "/usr/local/bin/wine")
        let provider = makeProvider(
            existingURLs: [homebrewURL, usrLocalURL],
            executableURLs: [homebrewURL, usrLocalURL],
            commandResults: [
                wineRequest(homebrewURL): .success(
                    CommandResult(exitCode: 0, stdout: "wine-10.0\n", stderr: "", duration: 0.01)
                ),
                wineRequest(usrLocalURL): .success(
                    CommandResult(exitCode: 0, stdout: "wine-8.0\n", stderr: "", duration: 0.01)
                )
            ]
        )

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.version, "10.0")
        XCTAssertEqual(dependency.installPath, homebrewURL.path)
    }

    func testMissingAllowedPathsReturnsMissing() async {
        let provider = makeProvider(existingURLs: [], executableURLs: [], commandResults: [:])

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .missing)
        XCTAssertEqual(dependency.missingReason, "Wine bulunamadı.")
        XCTAssertEqual(
            dependency.suggestedAction,
            "Wine’ı desteklenen konumlardan birine manuel olarak kurmanız gerekir."
        )
    }

    func testExistingButNotExecutablePathReturnsMissing() async {
        let wineURL = URL(fileURLWithPath: "/opt/homebrew/bin/wine")
        let provider = makeProvider(existingURLs: [wineURL], executableURLs: [], commandResults: [:])

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .missing)
    }

    func testTimeoutReturnsUnknown() async {
        let dependency = await diagnoseWine(error: .timedOut)

        XCTAssertEqual(dependency.status, .unknown)
        XCTAssertEqual(dependency.userFacingDescription, "Wine durumu doğrulanamadı.")
    }

    func testNonZeroReturnsUnknown() async {
        let dependency = await diagnoseWine(error: .nonZeroExit(1))

        XCTAssertEqual(dependency.status, .unknown)
    }

    func testLaunchFailedReturnsUnknown() async {
        let dependency = await diagnoseWine(error: .launchFailed("failed"))

        XCTAssertEqual(dependency.status, .unknown)
    }

    func testParseVersionMapsKnownOutputs() {
        XCTAssertEqual(WineDiagnosticProvider.parseVersion(from: "wine-9.0\n"), "9.0")
        XCTAssertEqual(WineDiagnosticProvider.parseVersion(from: "wine-8.21-staging"), "8.21-staging")
        XCTAssertNil(WineDiagnosticProvider.parseVersion(from: ""))
        XCTAssertNil(WineDiagnosticProvider.parseVersion(from: "not-wine"))
    }

    func testVersionParsesFromStderrWhenStdoutIsUnusable() async {
        let wineURL = URL(fileURLWithPath: "/opt/homebrew/bin/wine")
        let provider = makeProvider(
            existingURLs: [wineURL],
            executableURLs: [wineURL],
            commandResults: [
                wineRequest(wineURL): .success(
                    CommandResult(
                        exitCode: 0,
                        stdout: "unexpected\n",
                        stderr: "wine-8.21-staging\n",
                        duration: 0.01
                    )
                )
            ]
        )

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .ready)
        XCTAssertEqual(dependency.version, "8.21-staging")
    }

    func testMalformedVersionOutputReturnsReadyWithoutVersion() async {
        let wineURL = URL(fileURLWithPath: "/opt/homebrew/bin/wine")
        let provider = makeProvider(
            existingURLs: [wineURL],
            executableURLs: [wineURL],
            commandResults: [
                wineRequest(wineURL): .success(
                    CommandResult(exitCode: 0, stdout: "unexpected\n", stderr: "", duration: 0.01)
                )
            ]
        )

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .ready)
        XCTAssertNil(dependency.version)
        XCTAssertEqual(dependency.userFacingDescription, "Wine bulundu ancak sürüm bilgisi ayrıştırılamadı.")
    }

    func testProviderUsesOnlyExplicitAllowedURLs() async {
        let pathURL = URL(fileURLWithPath: "/usr/bin/wine")
        let provider = WineDiagnosticProvider(
            commandRunner: FakeCommandRunner(results: [:]),
            fileChecker: FakeFileChecker(existingURLs: [pathURL], executableURLs: [pathURL]),
            timeoutSeconds: 2
        )

        let dependency = await provider.diagnose()

        XCTAssertEqual(dependency.status, .missing)
        XCTAssertNil(dependency.installPath)
    }

    private func diagnoseWine(error: CommandError) async -> RuntimeDependency {
        let wineURL = URL(fileURLWithPath: "/opt/homebrew/bin/wine")
        let provider = makeProvider(
            existingURLs: [wineURL],
            executableURLs: [wineURL],
            commandResults: [wineRequest(wineURL): .failure(error)]
        )

        return await provider.diagnose()
    }

    private func makeProvider(
        existingURLs: Set<URL>,
        executableURLs: Set<URL>,
        commandResults: [CommandRequest: Result<CommandResult, CommandError>]
    ) -> WineDiagnosticProvider {
        WineDiagnosticProvider(
            commandRunner: FakeCommandRunner(results: commandResults),
            fileChecker: FakeFileChecker(existingURLs: existingURLs, executableURLs: executableURLs),
            timeoutSeconds: 2
        )
    }

    private func wineRequest(_ wineURL: URL) -> CommandRequest {
        CommandRequest(
            executableURL: wineURL,
            arguments: ["--version"],
            environment: [:],
            timeoutSeconds: 2,
            purpose: .wineVersionCheck
        )
    }
}

private struct FakeFileChecker: FileChecking {
    let existingURLs: Set<URL>
    let executableURLs: Set<URL>

    func fileExists(at url: URL) -> Bool {
        existingURLs.contains(url)
    }

    func isExecutableFile(at url: URL) -> Bool {
        executableURLs.contains(url)
    }
}
