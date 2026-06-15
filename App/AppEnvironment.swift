import Foundation

struct AppEnvironment: Sendable {
    let profileManager: GameProfileManaging
    let bundledProfileLoader: BundledGameProfileLoader
    let fileSelectionService: any FileSelectionServicing
    let bookmarkManager: any BookmarkManaging
    let gameFolderDetector: any GameFolderDetecting

    @MainActor
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
            bundledProfileLoader: BundledGameProfileLoader(),
            fileSelectionService: FileSelectionService(),
            bookmarkManager: BookmarkManager(),
            gameFolderDetector: GameFolderDetector(fileSystem: fileSystem)
        )
    }
}
