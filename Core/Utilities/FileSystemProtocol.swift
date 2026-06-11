import Foundation

protocol FileSystemProtocol: Sendable {
    func createDirectory(at url: URL) throws
    func fileExists(at url: URL) -> Bool
    func contentsOfDirectory(at url: URL) throws -> [URL]
    func readData(at url: URL) throws -> Data
    func writeData(_ data: Data, to url: URL) throws
    func removeItem(at url: URL) throws
}

