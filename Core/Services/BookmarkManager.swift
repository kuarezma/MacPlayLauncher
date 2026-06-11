import Foundation

struct BookmarkManager: Sendable {
    func createBookmark(for url: URL) throws -> Data {
        throw MacPlayError.bookmarkUnavailable
    }

    func resolveBookmark(_ data: Data) throws -> URL {
        throw MacPlayError.bookmarkUnavailable
    }
}

