import Foundation

struct AppEnvironment: Sendable {
    let profileManager: GameProfileManaging
    let bundledProfileLoader: BundledGameProfileLoader
    let fileSelectionService: any FileSelectionServicing
    let bookmarkManager: any BookmarkManaging
    let gameFolderDetector: any GameFolderDetecting
    let dependencyDiagnosticService: any DependencyDiagnosticServicing
    let diagnosticActivationPolicy: DiagnosticActivationPolicy?
    let runReadinessEvaluator: any RunReadinessEvaluating

    init(
        profileManager: GameProfileManaging,
        bundledProfileLoader: BundledGameProfileLoader,
        fileSelectionService: any FileSelectionServicing,
        bookmarkManager: any BookmarkManaging,
        gameFolderDetector: any GameFolderDetecting,
        dependencyDiagnosticService: any DependencyDiagnosticServicing,
        diagnosticActivationPolicy: DiagnosticActivationPolicy? = nil,
        runReadinessEvaluator: any RunReadinessEvaluating
    ) {
        self.profileManager = profileManager
        self.bundledProfileLoader = bundledProfileLoader
        self.fileSelectionService = fileSelectionService
        self.bookmarkManager = bookmarkManager
        self.gameFolderDetector = gameFolderDetector
        self.dependencyDiagnosticService = dependencyDiagnosticService
        self.diagnosticActivationPolicy = diagnosticActivationPolicy
        self.runReadinessEvaluator = runReadinessEvaluator
    }

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
            gameFolderDetector: GameFolderDetector(fileSystem: fileSystem),
            dependencyDiagnosticService: SelectableDependencyDiagnosticService(
                mode: .staticOnly,
                policy: .production
            ),
            diagnosticActivationPolicy: .production,
            runReadinessEvaluator: DefaultRunReadinessEvaluator()
        )
    }

    @MainActor
    static var previewWithRealDiagnostics: AppEnvironment {
        let live = live
        return AppEnvironment(
            profileManager: live.profileManager,
            bundledProfileLoader: live.bundledProfileLoader,
            fileSelectionService: live.fileSelectionService,
            bookmarkManager: live.bookmarkManager,
            gameFolderDetector: live.gameFolderDetector,
            dependencyDiagnosticService: SelectableDependencyDiagnosticService(
                mode: .realReadOnly,
                policy: .internalRealReadOnly
            ),
            diagnosticActivationPolicy: .internalRealReadOnly,
            runReadinessEvaluator: live.runReadinessEvaluator
        )
    }
}
