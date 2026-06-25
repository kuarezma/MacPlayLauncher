import Foundation
@testable import MacPlayLauncher
import XCTest

final class CommandServiceTests: XCTestCase {
    func testDisplayResolutionSetAndRestoreUseFakeCommandRunner() {
        let displayplacerURL = URL(fileURLWithPath: "/tmp/displayplacer")
        let listRequest = commandRequest(
            executableURL: displayplacerURL,
            arguments: ["list"],
            timeoutSeconds: 5,
            purpose: .displayResolutionList
        )
        let setRequest = commandRequest(
            executableURL: displayplacerURL,
            arguments: ["id:12345 res:1280x800 hz:60 color_depth:8"],
            timeoutSeconds: 5,
            purpose: .displayResolutionSet
        )
        let restoreRequest = commandRequest(
            executableURL: displayplacerURL,
            arguments: ["id:12345 res:2560x1600 hz:60 color_depth:8"],
            timeoutSeconds: 5,
            purpose: .displayResolutionSet
        )
        let runner = FakeCommandRunner(results: [
            listRequest: .success(success(stdout: displayplacerListOutput())),
            setRequest: .success(success()),
            restoreRequest: .success(success())
        ])
        let service = DisplayResolutionService(
            commandRunner: runner,
            displayplacerURL: displayplacerURL,
            fileExists: { _ in true }
        )

        service.setGameResolution()
        service.restoreResolution()

        XCTAssertEqual(runner.requests, [listRequest, setRequest, restoreRequest])
    }

    func testDisplayResolutionSkipsCommandsWhenDisplayplacerIsMissing() {
        let runner = FakeCommandRunner(results: [:])
        let service = DisplayResolutionService(
            commandRunner: runner,
            displayplacerURL: URL(fileURLWithPath: "/tmp/missing-displayplacer"),
            fileExists: { _ in false }
        )

        service.setGameResolution()
        service.restoreResolution()

        XCTAssertTrue(runner.requests.isEmpty)
    }

    func testWineSteamLaunchUsesBottleAndWineDebugEnvironment() throws {
        let wineURL = URL(fileURLWithPath: "/tmp/wine")
        let launchRequest = commandRequest(
            executableURL: wineURL,
            arguments: ["--bottle", "CossacksBottle", "C:\\Program Files (x86)\\Steam\\steam.exe"],
            environment: ["PATH": "/usr/bin", "WINEDEBUG": "-all"],
            timeoutSeconds: 5,
            purpose: .wineSteamLaunch
        )
        let runner = FakeCommandRunner(results: [
            launchRequest: .success(success())
        ])
        let service = WineSteamService(
            commandRunner: runner,
            wineURL: wineURL,
            environmentProvider: { ["PATH": "/usr/bin"] },
            readinessBufferNanoseconds: 0,
            sleep: { _ in }
        )

        try service.launch(bottleName: "CossacksBottle")

        XCTAssertEqual(runner.requests, [launchRequest])
    }

    func testWineSteamReadinessUsesProcessMonitorThroughFakeCommandRunner() async throws {
        let lookupRequest = processLookupRequest(name: "steam.exe")
        let runner = FakeCommandRunner(results: [
            lookupRequest: .success(success())
        ])
        let service = WineSteamService(
            commandRunner: runner,
            readinessBufferNanoseconds: 0,
            sleep: { _ in }
        )

        try await service.waitForReadiness(timeout: 1)

        XCTAssertEqual(runner.requests, [lookupRequest])
    }

    func testGameProcessMonitorReportsRunningProcess() {
        let lookupRequest = processLookupRequest(name: "steam.exe")
        let runner = FakeCommandRunner(results: [
            lookupRequest: .success(success())
        ])

        let isRunning = GameProcessMonitor.isProcessRunning(
            name: "steam.exe",
            commandRunner: runner
        )

        XCTAssertTrue(isRunning)
        XCTAssertEqual(runner.requests, [lookupRequest])
    }

    func testGameProcessMonitorReportsMissingProcessOnCommandFailure() {
        let lookupRequest = processLookupRequest(name: "steam.exe")
        let runner = FakeCommandRunner(results: [
            lookupRequest: .failure(.nonZeroExit(1))
        ])

        let isRunning = GameProcessMonitor.isProcessRunning(
            name: "steam.exe",
            commandRunner: runner
        )

        XCTAssertFalse(isRunning)
        XCTAssertEqual(runner.requests, [lookupRequest])
    }

    func testGameProcessMonitorKillsKnownWineProcessesThroughFakeCommandRunner() {
        let targets = [
            "steam.exe", "steamwebhelper.exe", "steamservice.exe",
            "steamclient_loader", "winedevice.exe", "winewrapper.exe",
            "services.exe", "plugplay.exe", "svchost.exe"
        ]
        let killRequests = targets.map(processKillRequest)
        let runner = FakeCommandRunner(
            results: Dictionary(uniqueKeysWithValues: killRequests.map { ($0, .success(success())) })
        )

        GameProcessMonitor.killWineProcesses(commandRunner: runner)

        XCTAssertEqual(runner.requests, killRequests)
    }

    private func displayplacerListOutput() -> String {
        """
        Persistent screen id: 12345
        Mode 1: res:2560x1600 hz:60 color_depth:8 <-- current mode
        """
    }

    private func processLookupRequest(name: String) -> CommandRequest {
        commandRequest(
            executableURL: GameProcessMonitor.pgrepURL,
            arguments: ["-x", name],
            purpose: .processLookup
        )
    }

    private func processKillRequest(name: String) -> CommandRequest {
        commandRequest(
            executableURL: GameProcessMonitor.pkillURL,
            arguments: ["-f", name],
            purpose: .processKill
        )
    }

    private func commandRequest(
        executableURL: URL,
        arguments: [String],
        environment: [String: String] = [:],
        timeoutSeconds: TimeInterval = 2,
        purpose: CommandPurpose
    ) -> CommandRequest {
        CommandRequest(
            executableURL: executableURL,
            arguments: arguments,
            environment: environment,
            timeoutSeconds: timeoutSeconds,
            purpose: purpose
        )
    }

    private func success(stdout: String = "") -> CommandResult {
        CommandResult(exitCode: 0, stdout: stdout, stderr: "", duration: 0)
    }
}
