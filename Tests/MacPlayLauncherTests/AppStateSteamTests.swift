import Foundation
import XCTest
@testable import MacPlayLauncher

final class FakeSteamInstallService: SteamInstallServicing, @unchecked Sendable {
    var didCallOpenInstallPage = false
    var didCallOpenLibrary = false
    var didCallWaitForReadiness = false
    var shouldThrow = false
    var shouldThrowTimeout = false
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

    func waitForReadiness(timeout: TimeInterval) async throws {
        didCallWaitForReadiness = true
        if shouldThrowTimeout {
            throw SteamInstallError.readinessTimeout
        }
        if shouldThrow {
            throw SteamInstallError.appNotFound
        }
    }
}

final class AppStateSteamTests: XCTestCase {
    @MainActor
    func test_openSteamInstall_withValidAppID_callsService() {
        let context = makeContext()
        context.appState.steamInstallInput = "730"
        context.appState.openSteamInstall()

        XCTAssertTrue(context.fakeSteamService.didCallOpenInstallPage)
        XCTAssertEqual(context.fakeSteamService.lastOpenedAppID, "730")
        XCTAssertNotNil(context.appState.steamInstallMessage)
        XCTAssertNil(context.appState.steamInstallErrorMessage)
    }

    @MainActor
    func test_openSteamInstall_withStoreURL_extractsAppID() {
        let context = makeContext()
        context.appState.steamInstallInput = "https://store.steampowered.com/app/730/CSGO/"
        context.appState.openSteamInstall()

        XCTAssertTrue(context.fakeSteamService.didCallOpenInstallPage)
        XCTAssertEqual(context.fakeSteamService.lastOpenedAppID, "730")
    }

    @MainActor
    func test_openSteamInstall_withSteamURL_passesThrough() {
        let context = makeContext()
        context.appState.steamInstallInput = "steam://install/730"
        context.appState.openSteamInstall()

        XCTAssertTrue(context.fakeSteamService.didCallOpenInstallPage)
        XCTAssertEqual(context.fakeSteamService.lastOpenedAppID, "730")
    }

    @MainActor
    func test_openSteamInstall_withInvalidInput_setsErrorMessage() {
        let context = makeContext()
        context.appState.steamInstallInput = "invalid_input_string"
        context.appState.openSteamInstall()

        XCTAssertFalse(context.fakeSteamService.didCallOpenInstallPage)
        XCTAssertNil(context.appState.steamInstallMessage)
        XCTAssertEqual(
            context.appState.steamInstallErrorMessage,
            String(localized: "addGame.steam.error.invalidInput")
        )
    }

    @MainActor
    func test_openSteamInstall_whenServiceThrows_setsErrorMessage() {
        let context = makeContext()
        context.fakeSteamService.shouldThrow = true
        context.appState.steamInstallInput = "730"
        context.appState.openSteamInstall()

        XCTAssertTrue(context.fakeSteamService.didCallOpenInstallPage)
        XCTAssertNil(context.appState.steamInstallMessage)
        XCTAssertEqual(context.appState.steamInstallErrorMessage, String(localized: "steam_not_installed"))
    }

    @MainActor
    func test_openSteamInstall_withEmptyInput_opensLibrary() {
        let context = makeContext()
        context.appState.steamInstallInput = "   "
        context.appState.openSteamInstall()

        XCTAssertTrue(context.fakeSteamService.didCallOpenLibrary)
        XCTAssertNotNil(context.appState.steamInstallMessage)
        XCTAssertNil(context.appState.steamInstallErrorMessage)
    }

    @MainActor
    private func makeContext() -> SteamTestContext {
        let fakeSteamService = FakeSteamInstallService()
        let profileStoreURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
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
        return SteamTestContext(
            appState: AppState(environment: env),
            fakeSteamService: fakeSteamService
        )
    }
}

private struct SteamTestContext {
    let appState: AppState
    let fakeSteamService: FakeSteamInstallService
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
