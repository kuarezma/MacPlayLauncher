import Foundation
import XCTest
@testable import MacPlayLauncher

final class GameLaunchPlannerTests: XCTestCase {
    func testMakeLaunchPlanBuildsWineCommandAndEnvironment() throws {
        let gameFolder = URL(fileURLWithPath: "/tmp/game", isDirectory: true)
        let executable = gameFolder.appending(path: "cossacks3.exe")
        let prefixRoot = URL(fileURLWithPath: "/tmp/AppSupport/MacPlayLauncher", isDirectory: true)
        let prefixURL = prefixRoot.appending(path: "Prefixes/test-game", directoryHint: .isDirectory)

        let planner = DefaultGameLaunchPlanner(
            bookmarkManager: FakeLaunchBookmarkManager(
                executableURL: executable,
                workingDirectoryURL: gameFolder
            ),
            prefixManager: FakeLaunchPrefixManager(prefixURL: prefixURL),
            wineResolver: WineExecutableResolver(
                fileChecker: FakeLaunchFileChecker(existingExecutables: ["/opt/homebrew/bin/wine"]),
                allowedWineURLs: [URL(fileURLWithPath: "/opt/homebrew/bin/wine")]
            )
        )

        let plan = try planner.makeLaunchPlan(for: makeProfile())

        XCTAssertEqual(plan.wineURL.path, "/opt/homebrew/bin/wine")
        XCTAssertEqual(plan.arguments, [executable.path])
        XCTAssertEqual(plan.environment["WINEPREFIX"], prefixURL.path)
        XCTAssertEqual(plan.environment["WINEARCH"], "win64")
        XCTAssertEqual(plan.environment["DXVK_STATE_CACHE"], "1")
        XCTAssertEqual(plan.workingDirectoryURL, gameFolder)
    }

    func testMakeLaunchPlanRequiresExistingPrefix() {
        let planner = DefaultGameLaunchPlanner(
            bookmarkManager: FakeLaunchBookmarkManager(
                executableURL: URL(fileURLWithPath: "/tmp/game/cossacks3.exe"),
                workingDirectoryURL: URL(fileURLWithPath: "/tmp/game", isDirectory: true)
            ),
            prefixManager: FakeLaunchPrefixManager(prefixURL: nil),
            wineResolver: WineExecutableResolver(
                fileChecker: FakeLaunchFileChecker(existingExecutables: ["/opt/homebrew/bin/wine"])
            )
        )

        XCTAssertThrowsError(try planner.makeLaunchPlan(for: makeProfile())) { error in
            XCTAssertEqual(error as? MacPlayError, .prefixDirectoryMissing)
        }
    }

    private func makeProfile() -> GameProfile {
        GameProfile(
            schemaVersion: GameProfile.currentSchemaVersion,
            id: "test-game",
            displayName: "Test Game",
            executablePath: "/tmp/game/cossacks3.exe",
            workingDirectory: "/tmp/game",
            prefixPath: "Prefixes/test-game",
            executableBookmarkData: Data([1]),
            workingDirectoryBookmarkData: Data([2]),
            runtime: .wineDXVKMoltenVK,
            performanceMode: .balanced,
            wineArch: .win64,
            windowsVersion: .win10,
            dependencies: [],
            environment: ["DXVK_STATE_CACHE": "1"],
            launchArguments: [],
            knownIssues: [],
            lastPlayedAt: nil,
            totalPlayTimeMinutes: 0,
            launchCount: 0
        )
    }
}

private struct FakeLaunchBookmarkManager: BookmarkManaging {
    let executableURL: URL
    let workingDirectoryURL: URL

    func createBookmark(for url: URL) throws -> Data {
        Data([1])
    }

    func resolveBookmark(_ data: Data) throws -> URL {
        data == Data([1]) ? executableURL : workingDirectoryURL
    }
}

private final class FakeLaunchPrefixManager: PrefixManaging {
    let prefixURL: URL?

    init(prefixURL: URL?) {
        self.prefixURL = prefixURL
    }

    func directoryState(for profile: GameProfile) throws -> PrefixDirectoryState {
        PrefixDirectoryState(
            profileID: profile.id,
            displayName: profile.displayName,
            relativePath: profile.prefixPath,
            absolutePath: prefixURL?.path ?? "/missing",
            availability: prefixURL == nil ? .missing : .exists
        )
    }

    func createPrefixDirectory(for profile: GameProfile) throws -> PrefixDirectoryState {
        try directoryState(for: profile)
    }
}

private struct FakeLaunchFileChecker: FileChecking {
    let existingExecutables: Set<String>

    func fileExists(at url: URL) -> Bool {
        existingExecutables.contains(url.path)
    }

    func isExecutableFile(at url: URL) -> Bool {
        existingExecutables.contains(url.path)
    }
}
