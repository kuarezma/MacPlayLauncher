import Foundation
@testable import MacPlayLauncher
import XCTest

final class FakeGameLauncher: GameLaunching, @unchecked Sendable {
    var launchedProfileID: String?
    var shouldThrow = false

    func launch(profile: GameProfile) throws -> GameLaunchResult {
        if shouldThrow {
            throw MacPlayError.launchFailed("Test fake error")
        }
        launchedProfileID = profile.id
        return GameLaunchResult(profileID: profile.id, processIdentifier: 1234)
    }
}

@MainActor
private struct FakeFileSelectionServiceForExe: FileSelectionServicing {
    let folderURL: URL?
    let executableURL: URL?

    func selectGameFolder() -> URL? { folderURL }
    func selectExecutableFile() -> URL? { executableURL }
}

final class AppStateLaunchTests: XCTestCase {
    @MainActor
    func test_launchGame_withValidProfile_launchesAndUpdatesStats() async throws {
        // Arrange
        let context = try makeContext()
        let testID = "test-game-id"
        let profile = GameProfile(
            schemaVersion: GameProfile.currentSchemaVersion,
            id: testID,
            displayName: "Test Game",
            executablePath: "game.exe",
            workingDirectory: nil,
            prefixPath: "Prefixes/\(testID)",
            executableBookmarkData: nil,
            workingDirectoryBookmarkData: nil,
            runtime: .wineDXVKMoltenVK,
            performanceMode: .balanced,
            wineArch: .win64,
            windowsVersion: .win10,
            dependencies: [],
            environment: [:],
            launchArguments: [],
            knownIssues: [],
            lastPlayedAt: nil,
            totalPlayTimeMinutes: 0,
            launchCount: 0
        )
        try context.profileManager.saveProfile(profile)
        context.appState.profiles = [profile]

        // Act
        context.appState.launchGame(profileID: profile.id)

        // Assert
        XCTAssertEqual(context.fakeLauncher.launchedProfileID, profile.id)
        XCTAssertNil(context.appState.launchingProfileID)
        XCTAssertNil(context.appState.launchErrorMessage)

        let updatedProfile = context.appState.profiles.first { $0.id == profile.id }
        XCTAssertEqual(updatedProfile?.launchCount, 1)
        XCTAssertNotNil(updatedProfile?.lastPlayedAt)
    }

    @MainActor
    func test_launchGame_whenFails_setsErrorMessage() async throws {
        // Arrange
        let context = try makeContext()
        let failingID = "failing-game-id"
        let profile = GameProfile(
            schemaVersion: GameProfile.currentSchemaVersion,
            id: failingID,
            displayName: "Failing Game",
            executablePath: "game.exe",
            workingDirectory: nil,
            prefixPath: "Prefixes/\(failingID)",
            executableBookmarkData: nil,
            workingDirectoryBookmarkData: nil,
            runtime: .wineDXVKMoltenVK,
            performanceMode: .balanced,
            wineArch: .win64,
            windowsVersion: .win10,
            dependencies: [],
            environment: [:],
            launchArguments: [],
            knownIssues: [],
            lastPlayedAt: nil,
            totalPlayTimeMinutes: 0,
            launchCount: 0
        )
        try context.profileManager.saveProfile(profile)
        context.appState.profiles = [profile]
        context.fakeLauncher.shouldThrow = true

        // Act
        context.appState.launchGame(profileID: profile.id)

        // Assert
        XCTAssertNil(context.appState.launchingProfileID)
        XCTAssertNotNil(context.appState.launchErrorMessage)

        let updatedProfile = context.appState.profiles.first { $0.id == profile.id }
        XCTAssertEqual(updatedProfile?.launchCount, 0)
        XCTAssertNil(updatedProfile?.lastPlayedAt)
    }

    @MainActor
    func test_selectExecutableForAddGame_rejectsNonExe() async throws {
        // Arrange
        let context = try makeContext(executableURL: URL(fileURLWithPath: "/test/game.bin"))
        context.appState.addGameForm.selectedFolderURL = URL(fileURLWithPath: "/test")

        // Act
        context.appState.selectExecutableForAddGame()

        // Assert
        XCTAssertNil(context.appState.addGameForm.selectedExecutableURL)
        XCTAssertEqual(
            context.appState.addGameForm.errorMessage,
            "Sadece .exe uzantılı Windows çalıştırılabilir dosyaları desteklenmektedir."
        )
    }

    @MainActor
    private func makeContext(
        executableURL: URL = URL(fileURLWithPath: "/test/game.exe")
    ) throws -> LaunchTestContext {
        let fakeLauncher = FakeGameLauncher()
        let profileStoreURL = try temporaryDirectory()
        let fileSystem = LocalFileSystem()
        let profileManager = GameProfileManager(
            store: JSONStore<GameProfile>(directoryURL: profileStoreURL, fileSystem: fileSystem)
        )
        let prefixManager = PrefixManager(
            appSupportURL: profileStoreURL.deletingLastPathComponent(),
            fileSystem: fileSystem
        )
        let env = AppEnvironment(
            profileManager: profileManager,
            bundledProfileLoader: BundledGameProfileLoader(bundle: .main),
            fileSelectionService: FakeFileSelectionServiceForExe(folderURL: nil, executableURL: executableURL),
            bookmarkManager: BookmarkManager(),
            gameFolderDetector: GameFolderDetector(fileSystem: fileSystem),
            dependencyDiagnosticService: StaticDependencyDiagnosticService(),
            runReadinessEvaluator: DefaultRunReadinessEvaluator(),
            prefixManager: prefixManager,
            steamInstallService: FakeSteamInstallService(),
            gameLauncher: fakeLauncher
        )
        return LaunchTestContext(
            appState: AppState(environment: env),
            fakeLauncher: fakeLauncher,
            profileManager: profileManager
        )
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

private struct LaunchTestContext {
    let appState: AppState
    let fakeLauncher: FakeGameLauncher
    let profileManager: GameProfileManager
}
