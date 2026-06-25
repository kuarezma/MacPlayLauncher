import Foundation
@testable import MacPlayLauncher
import XCTest

// MARK: - offline.txt detection

final class OfflineTxtDetectionTests: XCTestCase {
    func testDetectOfflineTxtNeedsActionWhenFileExists() async throws {
        let gameDir = try makeTempGameDir()
        defer { try? FileManager.default.removeItem(at: gameDir) }

        let settingsDir = gameDir.appending(path: "steam_settings", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: settingsDir, withIntermediateDirectories: true)
        let offlineTxt = settingsDir.appending(path: "offline.txt", directoryHint: .notDirectory)
        try "".write(to: offlineTxt, atomically: true, encoding: .utf8)
        try "fake.exe".write(to: gameDir.appending(path: "cossacks.exe"), atomically: true, encoding: .utf8)

        let service = CossacksSetupService(localPortGameDirectory: gameDir)
        let steps = await service.detectSteps()
        let step = try XCTUnwrap(steps.first { $0.id == "offlineTxt" })

        if case .needsAction = step.status {
            XCTAssertTrue(step.canAutoFix)
            XCTAssertEqual(step.automationTarget, .offlineTxt)
            XCTAssertNotNil(step.actionLabel)
        } else {
            XCTFail("Expected needsAction, got \(step.status)")
        }
    }

    func testDetectOfflineTxtOkWhenFileAbsent() async throws {
        let gameDir = try makeTempGameDir()
        defer { try? FileManager.default.removeItem(at: gameDir) }

        let service = CossacksSetupService(localPortGameDirectory: gameDir)
        let steps = await service.detectSteps()
        let step = try XCTUnwrap(steps.first { $0.id == "offlineTxt" })

        if case .ok = step.status {
            XCTAssertFalse(step.canAutoFix)
            XCTAssertNil(step.automationTarget)
        } else {
            XCTFail("Expected ok, got \(step.status)")
        }
    }

    func testDetectStepsContainsOfflineTxtStep() async {
        let service = CossacksSetupService()
        let steps = await service.detectSteps()
        XCTAssertTrue(steps.contains { $0.id == "offlineTxt" })
    }

    private func makeTempGameDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appending(path: "OfflineTxtTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}

// MARK: - offline.txt rename (SetupInstallerService)

final class OfflineTxtRenameTests: XCTestCase {
    func testRenameSucceedsAndReturnsCompleted() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: "OfflineTxtRename-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let offlineTxtURL = tempDir.appending(path: "offline.txt", directoryHint: .notDirectory)
        try "".write(to: offlineTxtURL, atomically: true, encoding: .utf8)

        let service = SetupInstallerService(
            commandRunner: NoOpCommandRunner(),
            fileChecker: FileManagerFileChecker(),
            offlineTxtURL: offlineTxtURL
        )

        let result = try await service.install(target: .offlineTxt)

        XCTAssertEqual(result, .completed("Çevrimdışı kısıtlaması devre dışı bırakıldı."))
        XCTAssertFalse(FileManager.default.fileExists(atPath: offlineTxtURL.path))
        let disabledURL = tempDir.appending(path: "offline.txt.disabled", directoryHint: .notDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: disabledURL.path))
    }

    func testRenameWhenFileAlreadyAbsentReturnsCompleted() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: "OfflineTxtRenameAbsent-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let offlineTxtURL = tempDir.appending(path: "offline.txt", directoryHint: .notDirectory)
        let service = SetupInstallerService(
            commandRunner: NoOpCommandRunner(),
            fileChecker: FileManagerFileChecker(),
            offlineTxtURL: offlineTxtURL
        )

        let result = try await service.install(target: .offlineTxt)

        XCTAssertEqual(result, .completed("Çevrimdışı kısıtlaması zaten yok."))
    }

    func testExistingDisabledFileIsReplacedOnRename() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: "OfflineTxtRenameOverwrite-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let offlineTxtURL = tempDir.appending(path: "offline.txt", directoryHint: .notDirectory)
        let disabledURL = tempDir.appending(path: "offline.txt.disabled", directoryHint: .notDirectory)
        try "new".write(to: offlineTxtURL, atomically: true, encoding: .utf8)
        try "old".write(to: disabledURL, atomically: true, encoding: .utf8)

        let service = SetupInstallerService(
            commandRunner: NoOpCommandRunner(),
            fileChecker: FileManagerFileChecker(),
            offlineTxtURL: offlineTxtURL
        )

        let result = try await service.install(target: .offlineTxt)

        XCTAssertEqual(result, .completed("Çevrimdışı kısıtlaması devre dışı bırakıldı."))
        let content = try String(contentsOf: disabledURL, encoding: .utf8)
        XCTAssertEqual(content, "new")
    }
}

// MARK: - Exit-53 → AppState alert

@MainActor
final class Exit53AlertTests: XCTestCase {
    func testAppStateShowsAlertOnExit53Notification() async throws {
        let appState = makeAppState()

        NotificationCenter.default.post(
            name: .gameProcessDidTerminate,
            object: nil,
            userInfo: ["profileID": "test-game", "exitCode": Int32(53)]
        )

        // Allow Task { @MainActor in } inside observer to run
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertNotNil(appState.launchExitAlertMessage)
        XCTAssertTrue(
            appState.launchExitAlertMessage?.contains("53") == true
                || appState.launchExitAlertMessage?.contains("offline") == true
        )
    }

    func testAppStateIgnoresNonExit53Notification() async throws {
        let appState = makeAppState()

        NotificationCenter.default.post(
            name: .gameProcessDidTerminate,
            object: nil,
            userInfo: ["profileID": "test-game", "exitCode": Int32(0)]
        )

        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertNil(appState.launchExitAlertMessage)
    }

    func testAppStateIgnoresNotificationWithoutExitCode() async throws {
        let appState = makeAppState()

        NotificationCenter.default.post(
            name: .gameProcessDidTerminate,
            object: nil,
            userInfo: ["profileID": "test-game"]
        )

        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertNil(appState.launchExitAlertMessage)
    }

    private func makeAppState() -> AppState {
        let fileSystem = LocalFileSystem()
        let profileStoreURL = FileManager.default.temporaryDirectory
            .appending(path: "Exit53Tests-\(UUID().uuidString)")
        let prefixManager = PrefixManager(
            appSupportURL: profileStoreURL,
            fileSystem: fileSystem
        )
        let env = AppEnvironment(
            profileManager: GameProfileManager(
                store: JSONStore<GameProfile>(
                    directoryURL: profileStoreURL,
                    fileSystem: fileSystem
                )
            ),
            bundledProfileLoader: BundledGameProfileLoader(bundle: .main),
            fileSelectionService: FakeExit53FileSelectionService(),
            bookmarkManager: BookmarkManager(),
            gameFolderDetector: GameFolderDetector(fileSystem: fileSystem),
            dependencyDiagnosticService: StaticDependencyDiagnosticService(),
            runReadinessEvaluator: DefaultRunReadinessEvaluator(),
            prefixManager: prefixManager,
            steamInstallService: FakeSteamInstallService()
        )
        return AppState(environment: env)
    }
}

// MARK: - Fakes / Stubs

private struct NoOpCommandRunner: CommandRunning {
    func run(_ request: CommandRequest) async throws -> CommandResult {
        CommandResult(exitCode: 0, stdout: "", stderr: "", duration: 0)
    }
}

@MainActor
private struct FakeExit53FileSelectionService: FileSelectionServicing {
    func selectGameFolder() -> URL? { nil }
    func selectExecutableFile() -> URL? { nil }
}
