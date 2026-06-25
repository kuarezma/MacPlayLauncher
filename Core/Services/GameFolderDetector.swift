import Foundation

protocol GameFolderDetecting: Sendable {
    func detectCossacks3(in folderURL: URL) throws -> DetectedGameFolder?
}

struct DetectedGameFolder: Equatable, Sendable {
    let displayName: String
    let executableURL: URL
}

struct GameFolderDetector: GameFolderDetecting {
    private let fileSystem: FileSystemProtocol
    private let executableCandidates: Set<String>

    init(
        fileSystem: FileSystemProtocol = LocalFileSystem(),
        executableCandidates: Set<String> = [
            "cossacks3.exe",
            "cossacks 3.exe",
            "cossacks.exe"
        ]
    ) {
        self.fileSystem = fileSystem
        self.executableCandidates = executableCandidates.map { $0.lowercased() }
            .reduce(into: Set<String>()) { result, value in
                result.insert(value)
            }
    }

    func detectCossacks3(in folderURL: URL) throws -> DetectedGameFolder? {
        let contents = try fileSystem.contentsOfDirectory(at: folderURL)
        guard let executableURL = contents.first(where: isCossacks3Executable) else {
            return nil
        }

        return DetectedGameFolder(displayName: "Cossacks 3", executableURL: executableURL)
    }

    private func isCossacks3Executable(_ url: URL) -> Bool {
        executableCandidates.contains(url.lastPathComponent.lowercased())
    }
}
