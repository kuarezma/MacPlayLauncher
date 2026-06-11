import Foundation

struct LocalFileSystem: FileSystemProtocol {
    func createDirectory(at url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        guard fileExists(at: url) else {
            return []
        }

        return try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
    }

    func readData(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    func writeData(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic])
    }

    func removeItem(at url: URL) throws {
        guard fileExists(at: url) else {
            return
        }

        try FileManager.default.removeItem(at: url)
    }
}

