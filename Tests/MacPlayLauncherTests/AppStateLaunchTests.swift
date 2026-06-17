import Foundation
import XCTest
@testable import MacPlayLauncher

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

@MainActor
final class FakeSteamInstallService: SteamInstallServicing {
    var shouldThrowAppNotFound = false
    var shouldThrowTimeout = false

    func openInstallPage(for appID: String) throws {
        if shouldThrowAppNotFound {
            throw SteamInstallError.appNotFound
        }
    }

    func openLibrary() throws {
        if shouldThrowAppNotFound {
            throw SteamInstallError.appNotFound
        }
    }

    func waitForReadiness(timeout: TimeInterval) async throws {
        if shouldThrowTimeout {
            throw SteamInstallError.readinessTimeout
        }
        if shouldThrowAppNotFound {
            throw SteamInstallError.appNotFound
        }
    }
}

@MainActor
final class AppStateLaunchTests: XCTestCase {
    var appState: AppState!
    var fakeLauncher: FakeGameLauncher!
    var profileManager: GameProfileManager!
    var prefixManager: PrefixManager!

    override func setUp() async throws {
        try await super.setUp()
        fakeLauncher = FakeGameLauncher()
        
        let profileStoreURL = try temporaryDirectory()
        let fileSystem = LocalFileSystem()
        profileManager = GameProfileManager(
            store: JSONStore<GameProfile>(directoryURL: profileStoreURL, fileSystem: fileSystem)
        )
        prefixManager = PrefixManager(
            appSupportURL: profileStoreURL.deletingLastPathComponent(),
            fileSystem: fileSystem
        )

        let env = AppEnvironment(
            profileManager: profileManager,
            bundledProfileLoader: BundledGameProfileLoader(bundle: .main),
            fileSelectionService: FakeFileSelectionServiceForExe(folderURL: nil, executableURL: URL(fileURLWithPath: "/test/game.exe")),
            bookmarkManager: BookmarkManager(),
            gameFolderDetector: GameFolderDetector(fileSystem: fileSystem),
            dependencyDiagnosticService: StaticDependencyDiagnosticService(),
            runReadinessEvaluator: DefaultRunReadinessEvaluator(),
            prefixManager: prefixManager,
            steamInstallService: FakeSteamInstallService(),
            gameLauncher: fakeLauncher
        )
        appState = AppState(environment: env)
    }

    func test_launchGame_withValidProfile_launchesAndUpdatesStats() async throws {
        // Arrange
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
        try profileManager.saveProfile(profile)
        appState.profiles = [profile]

        // Act
        appState.launchGame(profileID: profile.id)

        // Assert
        XCTAssertEqual(fakeLauncher.launchedProfileID, profile.id)
        XCTAssertNil(appState.launchingProfileID)
        XCTAssertNil(appState.launchErrorMessage)
        
        let updatedProfile = appState.profiles.first { $0.id == profile.id }
        XCTAssertEqual(updatedProfile?.launchCount, 1)
        XCTAssertNotNil(updatedProfile?.lastPlayedAt)
    }

    func test_launchGame_whenFails_setsErrorMessage() async throws {
        // Arrange
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
        try profileManager.saveProfile(profile)
        appState.profiles = [profile]
        fakeLauncher.shouldThrow = true

        // Act
        appState.launchGame(profileID: profile.id)

        // Assert
        XCTAssertNil(appState.launchingProfileID)
        XCTAssertNotNil(appState.launchErrorMessage)
        
        let updatedProfile = appState.profiles.first { $0.id == profile.id }
        XCTAssertEqual(updatedProfile?.launchCount, 0)
        XCTAssertNil(updatedProfile?.lastPlayedAt)
    }

    func test_selectExecutableForAddGame_rejectsNonExe() async throws {
        // Arrange
        let env = AppEnvironment(
            profileManager: profileManager,
            bundledProfileLoader: BundledGameProfileLoader(bundle: .main),
            fileSelectionService: FakeFileSelectionServiceForExe(folderURL: nil, executableURL: URL(fileURLWithPath: "/test/game.bin")),
            bookmarkManager: BookmarkManager(),
            gameFolderDetector: GameFolderDetector(fileSystem: LocalFileSystem()),
            dependencyDiagnosticService: StaticDependencyDiagnosticService(),
            runReadinessEvaluator: DefaultRunReadinessEvaluator(),
            prefixManager: prefixManager,
            steamInstallService: FakeSteamInstallService(),
            gameLauncher: fakeLauncher
        )
        appState = AppState(environment: env)
        appState.addGameForm.selectedFolderURL = URL(fileURLWithPath: "/test")

        // Act
        appState.selectExecutableForAddGame()

        // Assert
        XCTAssertNil(appState.addGameForm.selectedExecutableURL)
        XCTAssertEqual(appState.addGameForm.errorMessage, "Sadece .exe uzantılı Windows çalıştırılabilir dosyaları desteklenmektedir.")
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
