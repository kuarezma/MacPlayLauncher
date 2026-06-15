import Foundation

struct AppEnvironment: Sendable {
    let profileManager: GameProfileManaging
    let bundledProfileLoader: BundledGameProfileLoader

    static var live: AppEnvironment {
        let fileSystem = LocalFileSystem()
        let baseURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        let appSupportURL = baseURL.appending(path: "MacPlayLauncher", directoryHint: .isDirectory)
        let store = JSONStore<GameProfile>(directoryURL: appSupportURL.appending(path: "Profiles"), fileSystem: fileSystem)
        return AppEnvironment(
            profileManager: GameProfileManager(store: store),
            bundledProfileLoader: BundledGameProfileLoader()
        )
    }
}
