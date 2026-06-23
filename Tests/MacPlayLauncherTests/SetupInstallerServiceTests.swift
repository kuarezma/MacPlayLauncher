import Foundation
@testable import MacPlayLauncher
import XCTest

final class SetupInstallerServiceTests: XCTestCase {
    func testCrossOverInstallUsesHomebrewCaskCommand() async throws {
        let runner = RecordingCommandRunner()
        let brewURL = URL(fileURLWithPath: "/opt/homebrew/bin/brew")
        let service = SetupInstallerService(
            commandRunner: runner,
            fileChecker: FakeSetupFileChecker(existingExecutableURLs: [brewURL])
        )

        let result = try await service.install(target: .crossOver)

        XCTAssertEqual(result, .waitingForUser("CrossOver kuruldu. Açılan pencerede trial/lisans adımını onaylayın."))
        XCTAssertTrue(
            runner.requests.contains {
                $0.executableURL.path == brewURL.path
                    && $0.arguments == ["install", "--cask", "crossover"]
                    && $0.purpose == .crossOverInstall
            }
        )
    }

    func testDisplayplacerInstallOpensHomebrewTerminalWhenBrewIsMissing() async throws {
        let runner = RecordingCommandRunner()
        let service = SetupInstallerService(
            commandRunner: runner,
            fileChecker: FakeSetupFileChecker(existingExecutableURLs: [])
        )

        let result = try await service.install(target: .displayplacer)

        if case .waitingForUser(let message) = result {
            XCTAssertTrue(message.contains("Homebrew"))
        } else {
            XCTFail("Expected waitingForUser result.")
        }
        XCTAssertEqual(runner.requests.first?.executableURL.path, "/usr/bin/open")
        XCTAssertEqual(runner.requests.first?.purpose, .homebrewInstallPrompt)
        XCTAssertTrue(
            runner.requests.first?.arguments.first?.hasSuffix("MacPlayLauncher-Homebrew-Install.command") == true
        )
    }

    func testBottleCreateUsesCossacksBottleAndWin10Template() async throws {
        let runner = RecordingCommandRunner()
        let crossOverURL = URL(fileURLWithPath: "/Applications/CrossOver.app")
        let cxbottleURL = URL(
            fileURLWithPath: "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/cxbottle"
        )
        let service = SetupInstallerService(
            commandRunner: runner,
            fileChecker: FakeSetupFileChecker(
                existingFileURLs: [crossOverURL],
                existingExecutableURLs: [cxbottleURL]
            )
        )

        let result = try await service.install(target: .bottle)

        XCTAssertEqual(result, .completed("'Cossacks3' bottle oluşturuldu."))
        XCTAssertEqual(runner.requests.first?.executableURL.path, cxbottleURL.path)
        XCTAssertEqual(
            runner.requests.first?.arguments,
            ["--bottle", "Cossacks3", "--create", "--template", "win10_64"]
        )
        XCTAssertEqual(runner.requests.first?.purpose, .bottleCreate)
    }

    func testSteamSetupLaunchesInstalledSteamAndWaitsForUserLogin() async throws {
        let runner = RecordingCommandRunner()
        let cxstartURL = URL(
            fileURLWithPath: "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/cxstart"
        )
        let steamURL = URL(fileURLWithPath: "/tmp/fake-steam.exe")
        let service = SetupInstallerService(
            commandRunner: runner,
            fileChecker: FakeSetupFileChecker(
                existingFileURLs: [steamURL],
                existingExecutableURLs: [cxstartURL]
            ),
            steamExecutableURL: steamURL
        )

        let result = try await service.install(target: .steam)

        if case .waitingForUser(let message) = result {
            XCTAssertTrue(message.contains("giriş"))
        } else {
            XCTFail("Expected waitingForUser result.")
        }
        XCTAssertEqual(runner.requests.first?.executableURL.path, cxstartURL.path)
        XCTAssertEqual(
            runner.requests.first?.arguments,
            ["--bottle", "Cossacks3", "--no-wait", #"C:\Program Files (x86)\Steam\steam.exe"#]
        )
        XCTAssertEqual(runner.requests.first?.purpose, .steamSetup)
    }

    func testUnsupportedShaderPatchIsNotInstalledBySetupInstaller() async {
        let service = SetupInstallerService(
            commandRunner: RecordingCommandRunner(),
            fileChecker: FakeSetupFileChecker(existingExecutableURLs: [])
        )

        do {
            _ = try await service.install(target: .shaderPatch)
            XCTFail("Expected unsupported target error.")
        } catch let error as SetupInstallerError {
            XCTAssertEqual(error, .unsupportedTarget("Grafik yaması ayrı servisle uygulanır."))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private final class RecordingCommandRunner: CommandRunning, @unchecked Sendable {
    private let lock = NSLock()
    private var recordedRequests: [CommandRequest] = []

    var requests: [CommandRequest] {
        lock.withLock { recordedRequests }
    }

    func run(_ request: CommandRequest) async throws -> CommandResult {
        lock.withLock {
            recordedRequests.append(request)
        }
        return CommandResult(exitCode: 0, stdout: "", stderr: "", duration: 0)
    }
}

private struct FakeSetupFileChecker: FileChecking {
    private let existingFileURLs: Set<URL>
    private let existingExecutableURLs: Set<URL>

    init(existingFileURLs: Set<URL> = [], existingExecutableURLs: Set<URL>) {
        self.existingFileURLs = Set(existingFileURLs.map { $0.standardizedFileURL })
        self.existingExecutableURLs = Set(existingExecutableURLs.map { $0.standardizedFileURL })
    }

    func fileExists(at url: URL) -> Bool {
        existingFileURLs.contains(url.standardizedFileURL)
            || existingExecutableURLs.contains(url.standardizedFileURL)
    }

    func isExecutableFile(at url: URL) -> Bool {
        existingExecutableURLs.contains(url.standardizedFileURL)
    }
}
