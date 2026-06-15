import Foundation

protocol FileChecking: Sendable {
    func fileExists(at url: URL) -> Bool
    func isExecutableFile(at url: URL) -> Bool
}

struct FileManagerFileChecker: FileChecking {
    func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    func isExecutableFile(at url: URL) -> Bool {
        FileManager.default.isExecutableFile(atPath: url.path)
    }
}
