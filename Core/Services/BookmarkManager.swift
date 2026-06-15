import Foundation

protocol BookmarkManaging: Sendable {
    func createBookmark(for url: URL) throws -> Data
    func resolveBookmark(_ data: Data) throws -> URL
}

struct BookmarkResolution: Sendable {
    let url: URL
    let isStale: Bool
}

struct BookmarkManager: BookmarkManaging {
    private let resolveBookmarkData: @Sendable (Data) throws -> BookmarkResolution

    init() {
        self.resolveBookmarkData = { data in
            try BookmarkManager.resolveBookmarkData(data)
        }
    }

    init(resolveBookmarkData: @escaping @Sendable (Data) throws -> BookmarkResolution) {
        self.resolveBookmarkData = resolveBookmarkData
    }

    func createBookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    func resolveBookmark(_ data: Data) throws -> URL {
        let resolution = try resolveBookmarkData(data)
        guard !resolution.isStale else {
            throw MacPlayError.bookmarkStale
        }

        return resolution.url
    }

    private static func resolveBookmarkData(_ data: Data) throws -> BookmarkResolution {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: data,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return BookmarkResolution(url: url, isStale: isStale)
    }
}
