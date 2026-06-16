import Foundation

protocol PrefixManaging: Sendable {
    func directoryState(for profile: GameProfile) throws -> PrefixDirectoryState
    func createPrefixDirectory(for profile: GameProfile) throws -> PrefixDirectoryState
}

struct PrefixManager: PrefixManaging {
    private let appSupportURL: URL
    private let fileSystem: any FileSystemProtocol

    init(appSupportURL: URL, fileSystem: any FileSystemProtocol) {
        self.appSupportURL = appSupportURL
        self.fileSystem = fileSystem
    }

    func directoryState(for profile: GameProfile) throws -> PrefixDirectoryState {
        let url = try resolvedPrefixURL(for: profile)
        return makeState(for: profile, url: url)
    }

    func createPrefixDirectory(for profile: GameProfile) throws -> PrefixDirectoryState {
        let url = try resolvedPrefixURL(for: profile)
        if !fileSystem.fileExists(at: url) {
            try fileSystem.createDirectory(at: url)
        }

        return makeState(for: profile, url: url)
    }

    private func resolvedPrefixURL(for profile: GameProfile) throws -> URL {
        try PrefixPathValidator.validate(profile: profile)

        let prefixesRoot = appSupportURL.appending(path: "Prefixes", directoryHint: .isDirectory)
        let url = appSupportURL.appending(path: profile.prefixPath, directoryHint: .isDirectory)
        try PrefixPathValidator.validateResolved(url, prefixesRoot: prefixesRoot)
        return url
    }

    private func makeState(for profile: GameProfile, url: URL) -> PrefixDirectoryState {
        PrefixDirectoryState(
            profileID: profile.id,
            displayName: profile.displayName,
            relativePath: profile.prefixPath,
            absolutePath: url.path,
            availability: fileSystem.fileExists(at: url) ? .exists : .missing
        )
    }
}
