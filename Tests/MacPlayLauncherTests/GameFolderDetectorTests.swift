@testable import MacPlayLauncher
import XCTest

final class GameFolderDetectorTests: XCTestCase {
    func testDetectsCossacks3Executable() throws {
        let directory = try temporaryDirectory()
        let executableURL = directory.appending(path: "cossacks3.exe")
        try Data().write(to: executableURL)

        let detector = GameFolderDetector(fileSystem: LocalFileSystem())
        let result = try detector.detectCossacks3(in: directory)

        XCTAssertEqual(result?.displayName, "Cossacks 3")
        XCTAssertEqual(result?.executableURL.standardizedFileURL.path, executableURL.standardizedFileURL.path)
    }

    func testDetectsCossacks3ExecutableCaseInsensitively() throws {
        let directory = try temporaryDirectory()
        let executableURL = directory.appending(path: "COSSACKS 3.EXE")
        try Data().write(to: executableURL)

        let detector = GameFolderDetector(fileSystem: LocalFileSystem())
        let result = try detector.detectCossacks3(in: directory)

        XCTAssertEqual(result?.executableURL.standardizedFileURL.path, executableURL.standardizedFileURL.path)
        XCTAssertEqual(result?.displayName, "Cossacks 3")
    }

    func testReturnsNilWhenExecutableIsMissing() throws {
        let directory = try temporaryDirectory()
        try Data().write(to: directory.appending(path: "other.exe"))

        let detector = GameFolderDetector(fileSystem: LocalFileSystem())

        XCTAssertNil(try detector.detectCossacks3(in: directory))
    }
}
