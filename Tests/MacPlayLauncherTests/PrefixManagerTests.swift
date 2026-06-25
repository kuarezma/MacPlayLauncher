import Foundation
@testable import MacPlayLauncher
import XCTest

final class PrefixManagerTests: XCTestCase {
    func testDirectoryStateReportsMissingPrefix() throws {
        let fileSystem = RecordingFileSystem()
        let manager = makeManager(fileSystem: fileSystem)
        let profile = makeProfile()

        let state = try manager.directoryState(for: profile)

        XCTAssertEqual(state.availability, .missing)
        XCTAssertEqual(state.relativePath, "Prefixes/test-game")
        XCTAssertTrue(state.absolutePath.hasSuffix("/Prefixes/test-game"))
        XCTAssertTrue(fileSystem.createdDirectories.isEmpty)
    }

    func testDirectoryStateReportsExistingPrefix() throws {
        let fileSystem = RecordingFileSystem(existingDirectories: [prefixURL().path])
        let manager = makeManager(fileSystem: fileSystem)

        let state = try manager.directoryState(for: makeProfile())

        XCTAssertEqual(state.availability, .exists)
    }

    func testCreatePrefixDirectoryCreatesOnlyUnderPrefixesRoot() throws {
        let fileSystem = RecordingFileSystem()
        let manager = makeManager(fileSystem: fileSystem)

        let state = try manager.createPrefixDirectory(for: makeProfile())

        XCTAssertEqual(state.availability, .exists)
        XCTAssertEqual(fileSystem.createdDirectories, [prefixURL().path])
    }

    func testCreatePrefixDirectoryIsIdempotent() throws {
        let prefixPath = prefixURL().path
        let fileSystem = RecordingFileSystem(existingDirectories: [prefixPath])
        let manager = makeManager(fileSystem: fileSystem)

        let state = try manager.createPrefixDirectory(for: makeProfile())

        XCTAssertEqual(state.availability, .exists)
        XCTAssertTrue(fileSystem.createdDirectories.isEmpty)
    }

    func testInvalidPrefixPathRejectsTraversal() {
        let profile = makeProfile(prefixPath: "Prefixes/../escape", id: "../escape")

        XCTAssertThrowsError(try makeManager().directoryState(for: profile)) { error in
            XCTAssertEqual(error as? MacPlayError, .invalidPrefixPath)
        }
    }

    func testInvalidPrefixPathRejectsMismatchedProfileID() {
        let profile = makeProfile(prefixPath: "Prefixes/other-game", id: "test-game")

        XCTAssertThrowsError(try makeManager().directoryState(for: profile)) { error in
            XCTAssertEqual(error as? MacPlayError, .invalidPrefixPath)
        }
    }

    private func makeManager(fileSystem: RecordingFileSystem = RecordingFileSystem()) -> PrefixManager {
        PrefixManager(
            appSupportURL: appSupportURL(),
            fileSystem: fileSystem
        )
    }

    private func makeProfile(
        prefixPath: String = "Prefixes/test-game",
        id: String = "test-game"
    ) -> GameProfile {
        GameProfile(
            schemaVersion: GameProfile.currentSchemaVersion,
            id: id,
            displayName: "Test Game",
            executablePath: nil,
            workingDirectory: nil,
            prefixPath: prefixPath,
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
    }

    private func appSupportURL() -> URL {
        URL(fileURLWithPath: "/tmp/MacPlayLauncher-Tests/AppSupport", isDirectory: true)
    }

    private func prefixURL() -> URL {
        appSupportURL().appending(path: "Prefixes/test-game", directoryHint: .isDirectory)
    }
}

private final class RecordingFileSystem: FileSystemProtocol, @unchecked Sendable {
    private(set) var createdDirectories: [String] = []
    private var existingDirectories: Set<String>

    init(existingDirectories: [String] = []) {
        self.existingDirectories = Set(existingDirectories)
    }

    func createDirectory(at url: URL) throws {
        createdDirectories.append(url.path)
        existingDirectories.insert(url.path)
    }

    func fileExists(at url: URL) -> Bool {
        existingDirectories.contains(url.path)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        []
    }

    func readData(at url: URL) throws -> Data {
        Data()
    }

    func writeData(_ data: Data, to url: URL) throws {}

    func removeItem(at url: URL) throws {}
}
