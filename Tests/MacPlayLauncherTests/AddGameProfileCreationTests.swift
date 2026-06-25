@testable import MacPlayLauncher
import XCTest

@MainActor
final class AddGameProfileCreationTests: XCTestCase {
    func testSelectingFolderDetectsCossacks3AndSavesProfile() throws {
        let gameFolderURL = try temporaryDirectory()
        let executableURL = gameFolderURL.appending(path: "cossacks3.exe")
        try Data().write(to: executableURL)

        let profileStoreURL = try temporaryDirectory()
        let store = JSONStore<GameProfile>(directoryURL: profileStoreURL, fileSystem: LocalFileSystem())
        let profileManager = GameProfileManager(store: store)
        let appState = AppState(
            environment: AppEnvironment(
                profileManager: profileManager,
                bundledProfileLoader: BundledGameProfileLoader(bundle: .main),
                fileSelectionService: FakeFileSelectionService(folderURL: gameFolderURL, executableURL: executableURL),
                bookmarkManager: FakeBookmarkManager(),
                gameFolderDetector: GameFolderDetector(fileSystem: LocalFileSystem()),
                dependencyDiagnosticService: StaticDependencyDiagnosticService(),
                runReadinessEvaluator: DefaultRunReadinessEvaluator(),
                prefixManager: PrefixManager(
                    appSupportURL: profileStoreURL.deletingLastPathComponent(),
                    fileSystem: LocalFileSystem()
                ),
                steamInstallService: FakeSteamInstallService()
            )
        )

        appState.selectGameFolderForAddGame()
        appState.saveAddGameProfile()

        let savedProfile = try XCTUnwrap(try profileManager.loadProfiles().first)
        XCTAssertEqual(savedProfile.displayName, "Cossacks 3")
        XCTAssertEqual(savedProfile.workingDirectory, gameFolderURL.standardizedFileURL.path)
        XCTAssertEqual(savedProfile.workingDirectoryBookmarkData, FakeBookmarkManager.bookmarkData)
        XCTAssertEqual(savedProfile.runtime, .systemWineFallback)
        XCTAssertNil(savedProfile.crossOverBottleName)
        XCTAssertEqual(savedProfile.executablePath, executableURL.standardizedFileURL.path)
        XCTAssertEqual(savedProfile.executableBookmarkData, FakeBookmarkManager.bookmarkData)
        XCTAssertEqual(appState.selectedNavigationItem, .library)
        XCTAssertEqual(appState.selectedProfileID, savedProfile.id)
    }

    func testExecutableOutsideSelectedFolderShowsTurkishError() throws {
        let gameFolderURL = try temporaryDirectory()
        let outsideFolderURL = try temporaryDirectory()
        let executableURL = outsideFolderURL.appending(path: "game.exe")
        try Data().write(to: executableURL)
        let profileStoreURL = try temporaryDirectory()

        let appState = AppState(
            environment: AppEnvironment(
                profileManager: GameProfileManager(
                    store: JSONStore<GameProfile>(directoryURL: profileStoreURL, fileSystem: LocalFileSystem())
                ),
                bundledProfileLoader: BundledGameProfileLoader(bundle: .main),
                fileSelectionService: FakeFileSelectionService(folderURL: gameFolderURL, executableURL: executableURL),
                bookmarkManager: FakeBookmarkManager(),
                gameFolderDetector: GameFolderDetector(fileSystem: LocalFileSystem()),
                dependencyDiagnosticService: StaticDependencyDiagnosticService(),
                runReadinessEvaluator: DefaultRunReadinessEvaluator(),
                prefixManager: PrefixManager(
                    appSupportURL: profileStoreURL.deletingLastPathComponent(),
                    fileSystem: LocalFileSystem()
                ),
                steamInstallService: FakeSteamInstallService()
            )
        )

        appState.selectGameFolderForAddGame()
        appState.selectExecutableForAddGame()

        XCTAssertEqual(appState.addGameForm.errorMessage, String(localized: "error.executableOutsideGameFolder"))
        XCTAssertNil(appState.addGameForm.selectedExecutableURL)
    }
}

@MainActor
private struct FakeFileSelectionService: FileSelectionServicing {
    let folderURL: URL?
    let executableURL: URL?

    func selectGameFolder() -> URL? {
        folderURL
    }

    func selectExecutableFile() -> URL? {
        executableURL
    }
}

private struct FakeBookmarkManager: BookmarkManaging {
    static let bookmarkData = Data([7, 7, 7])

    func createBookmark(for url: URL) throws -> Data {
        Self.bookmarkData
    }

    func resolveBookmark(_ data: Data) throws -> URL {
        URL(fileURLWithPath: "/tmp/fake")
    }
}
