import Foundation

struct WineExecutableResolver: Sendable {
    private let fileChecker: any FileChecking
    private let allowedWineURLs: [URL]

    init(
        fileChecker: any FileChecking = FileManagerFileChecker(),
        allowedWineURLs: [URL] = Self.defaultAllowedWineURLs
    ) {
        self.fileChecker = fileChecker
        self.allowedWineURLs = allowedWineURLs
    }

    func resolve() -> URL? {
        allowedWineURLs.first { url in
            fileChecker.fileExists(at: url) && fileChecker.isExecutableFile(at: url)
        }
    }

    private static var defaultAllowedWineURLs: [URL] {
        [
            URL(fileURLWithPath: "/opt/homebrew/bin/wine"),
            URL(fileURLWithPath: "/usr/local/bin/wine")
        ]
    }
}
