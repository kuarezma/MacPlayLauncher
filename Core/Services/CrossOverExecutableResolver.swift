import Foundation

struct CrossOverExecutableResolver: Sendable {
    private let fileChecker: any FileChecking
    private let allowedURLs: [URL]

    init(
        fileChecker: any FileChecking = FileManagerFileChecker(),
        allowedURLs: [URL] = Self.defaultAllowedURLs
    ) {
        self.fileChecker = fileChecker
        self.allowedURLs = allowedURLs
    }

    func resolve() -> URL? {
        allowedURLs.first { url in
            fileChecker.fileExists(at: url) && fileChecker.isExecutableFile(at: url)
        }
    }

    static var defaultAllowedURLs: [URL] {
        [URL(fileURLWithPath: "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/cxstart")]
    }
}
