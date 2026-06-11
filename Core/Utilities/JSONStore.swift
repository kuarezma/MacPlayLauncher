import Foundation

struct JSONStore<Value: Codable & Sendable>: Sendable {
    private let directoryURL: URL
    private let fileSystem: any FileSystemProtocol

    init(directoryURL: URL, fileSystem: any FileSystemProtocol) {
        self.directoryURL = directoryURL
        self.fileSystem = fileSystem
    }

    func loadAll() throws -> [Value] {
        let files = try fileSystem.contentsOfDirectory(at: directoryURL)
            .filter { $0.pathExtension == "json" }

        return try files.map { fileURL in
            let data = try fileSystem.readData(at: fileURL)
            return try Self.makeDecoder().decode(Value.self, from: data)
        }
    }

    func load(named name: String) throws -> Value {
        let data = try fileSystem.readData(at: fileURL(named: name))
        return try Self.makeDecoder().decode(Value.self, from: data)
    }

    func save(_ value: Value, named name: String) throws {
        try fileSystem.createDirectory(at: directoryURL)
        let data = try Self.makeEncoder().encode(value)
        try fileSystem.writeData(data, to: fileURL(named: name))
    }

    func delete(named name: String) throws {
        try fileSystem.removeItem(at: fileURL(named: name))
    }

    private func fileURL(named name: String) -> URL {
        directoryURL.appending(path: "\(PathSanitizer.fileName(name)).json")
    }

    private static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
