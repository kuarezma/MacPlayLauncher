import Foundation
import XCTest
@testable import MacPlayLauncher

final class FakeSteamInstallService: SteamInstallServicing, @unchecked Sendable {
    var didCallOpenInstallPage = false
    var didCallOpenLibrary = false
    var shouldThrow = false
    var lastOpenedAppID: String?

    func openInstallPage(for appID: String) throws {
        didCallOpenInstallPage = true
        lastOpenedAppID = appID
        if shouldThrow {
            throw SteamInstallError.appNotFound
        }
    }

    func openLibrary() throws {
        didCallOpenLibrary = true
        if shouldThrow {
            throw SteamInstallError.appNotFound
        }
    }
}

@MainActor
final class AppStateSteamTests: XCTestCase {
    var appState: AppState!
    var fakeSteamService: FakeSteamInstallService!

    override func setUp() async throws {
        try await super.setUp()
        fakeSteamService = FakeSteamInstallService()
        
        let profileStoreURL = try temporaryDirectory()
        let env = AppEnvironment(
            profileManager: GameProfileManager(
                store: JSONStore<GameProfile>(directoryURL: profileStoreURL, fileSystem: LocalFileSystem())
            ),
            bundledProfileLoader: BundledGameProfileLoader(bundle: .main),
            fileSelectionService: FakeFileSelectionService2(folderURL: nil, executableURL: nil),
            bookmarkManager: FakeBookmarkManager2(),
            gameFolderDetector: GameFolderDetector(fileSystem: LocalFileSystem()),
            dependencyDiagnosticService: StaticDependencyDiagnosticService(),
            runReadinessEvaluator: DefaultRunReadinessEvaluator(),
            prefixManager: PrefixManager(
                appSupportURL: profileStoreURL.deletingLastPathComponent(),
                fileSystem: LocalFileSystem()
            ),
            steamInstallService: fakeSteamService
        )
        appState = AppState(environment: env)
    }

    func test_openSteamInstall_withValidAppID_callsService() {
        appState.steamInstallInput = "730"
        appState.openSteamInstall()

        XCTAssertTrue(fakeSteamService.didCallOpenInstallPage)
        XCTAssertEqual(fakeSteamService.lastOpenedAppID, "730")
        XCTAssertNotNil(appState.steamInstallMessage)
        XCTAssertNil(appState.steamInstallErrorMessage)
    }

    func test_openSteamInstall_withStoreURL_extractsAppID() {
        appState.steamInstallInput = "https://store.steampowered.com/app/730/CSGO/"
        appState.openSteamInstall()

        XCTAssertTrue(fakeSteamService.didCallOpenInstallPage)
        XCTAssertEqual(fakeSteamService.lastOpenedAppID, "730")
    }

    func test_openSteamInstall_withSteamURL_passesThrough() {
        appState.steamInstallInput = "steam://install/730"
        appState.openSteamInstall()

        XCTAssertTrue(fakeSteamService.didCallOpenInstallPage)
        XCTAssertEqual(fakeSteamService.lastOpenedAppID, "730")
    }

    func test_openSteamInstall_withInvalidInput_setsErrorMessage() {
        appState.steamInstallInput = "invalid_input_string"
        appState.openSteamInstall()

        XCTAssertFalse(fakeSteamService.didCallOpenInstallPage)
        XCTAssertNil(appState.steamInstallMessage)
        XCTAssertEqual(appState.steamInstallErrorMessage, String(localized: "addGame.steam.error.invalidInput"))
    }

    func test_openSteamInstall_whenServiceThrows_setsErrorMessage() {
        fakeSteamService.shouldThrow = true
        appState.steamInstallInput = "730"
        appState.openSteamInstall()

        XCTAssertTrue(fakeSteamService.didCallOpenInstallPage)
        XCTAssertNil(appState.steamInstallMessage)
        XCTAssertEqual(appState.steamInstallErrorMessage, String(localized: "steam_not_installed"))
    }

    func test_openSteamInstall_withEmptyInput_opensLibrary() {
        appState.steamInstallInput = "   "
        appState.openSteamInstall()

        XCTAssertTrue(fakeSteamService.didCallOpenLibrary)
        XCTAssertNotNil(appState.steamInstallMessage)
        XCTAssertNil(appState.steamInstallErrorMessage)
    }
    
    // Helpers
    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

@MainActor
private struct FakeFileSelectionService2: FileSelectionServicing {
    let folderURL: URL?
    let executableURL: URL?

    func selectGameFolder() -> URL? { folderURL }
    func selectExecutableFile() -> URL? { executableURL }
}

private struct FakeBookmarkManager2: BookmarkManaging {
    func createBookmark(for url: URL) throws -> Data { Data() }
    func resolveBookmark(_ data: Data) throws -> URL { URL(fileURLWithPath: "/tmp/fake") }
}
