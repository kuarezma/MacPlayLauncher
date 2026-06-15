import XCTest
@testable import MacPlayLauncher

final class BookmarkManagerTests: XCTestCase {
    func testCreateAndResolveBookmark() throws {
        let directory = try temporaryDirectory()
        let bookmarkManager = BookmarkManager()

        let bookmarkData = try bookmarkManager.createBookmark(for: directory)
        let resolvedURL = try bookmarkManager.resolveBookmark(bookmarkData)

        XCTAssertEqual(resolvedURL.standardizedFileURL.path, directory.standardizedFileURL.path)
    }

    func testResolveThrowsWhenBookmarkIsStale() {
        let bookmarkManager = BookmarkManager { _ in
            BookmarkResolution(url: URL(fileURLWithPath: "/tmp/stale"), isStale: true)
        }

        XCTAssertThrowsError(try bookmarkManager.resolveBookmark(Data([1, 2, 3]))) { error in
            XCTAssertEqual(error as? MacPlayError, .bookmarkStale)
        }
    }

    func testResolveThrowsForInvalidBookmarkData() {
        let bookmarkManager = BookmarkManager()

        XCTAssertThrowsError(try bookmarkManager.resolveBookmark(Data([1, 2, 3])))
    }
}
