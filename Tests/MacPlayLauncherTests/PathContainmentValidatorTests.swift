import XCTest
@testable import MacPlayLauncher

final class PathContainmentValidatorTests: XCTestCase {
    func testExecutableInsideSelectedFolderIsAccepted() throws {
        let folderURL = URL(fileURLWithPath: "/Games/Cossacks")
        let executableURL = URL(fileURLWithPath: "/Games/Cossacks/bin/game.exe")

        XCTAssertNoThrow(try PathContainmentValidator.validateExecutable(executableURL, isInside: folderURL))
    }

    func testSiblingFolderIsRejected() {
        let folderURL = URL(fileURLWithPath: "/Games/Cossacks")
        let executableURL = URL(fileURLWithPath: "/Games/CossacksFake/game.exe")

        XCTAssertThrowsError(try PathContainmentValidator.validateExecutable(executableURL, isInside: folderURL)) { error in
            XCTAssertEqual(error as? MacPlayError, .executableOutsideGameFolder)
        }
    }

    func testParentTraversalOutsideFolderIsRejected() {
        let folderURL = URL(fileURLWithPath: "/Games/Cossacks")
        let executableURL = URL(fileURLWithPath: "/Games/Cossacks/../Other/game.exe")

        XCTAssertThrowsError(try PathContainmentValidator.validateExecutable(executableURL, isInside: folderURL)) { error in
            XCTAssertEqual(error as? MacPlayError, .executableOutsideGameFolder)
        }
    }

    func testNonExecutableFileIsRejected() {
        let folderURL = URL(fileURLWithPath: "/Games/Cossacks")
        let executableURL = URL(fileURLWithPath: "/Games/Cossacks/game.txt")

        XCTAssertThrowsError(try PathContainmentValidator.validateExecutable(executableURL, isInside: folderURL)) { error in
            XCTAssertEqual(error as? MacPlayError, .invalidPath)
        }
    }
}
