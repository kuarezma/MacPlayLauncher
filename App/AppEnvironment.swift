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
    let prefixManager: any PrefixManaging
    let steamInstallService: any SteamInstallServicing
    let experimentalLaunchPolicy: ExperimentalLaunchPolicy
    let experimentalRunReadinessEvaluator: any RunReadinessEvaluating
    let gameLauncher: any GameLaunching
    let appSupportURL: URL

    init(
        profileManager: GameProfileManaging,
        bundledProfileLoader: BundledGameProfileLoader,
        fileSelectionService: any FileSelectionServicing,
        bookmarkManager: any BookmarkManaging,
        gameFolderDetector: any GameFolderDetecting,
        dependencyDiagnosticService: any DependencyDiagnosticServicing,
        diagnosticActivationPolicy: DiagnosticActivationPolicy? = nil,
        runReadinessEvaluator: any RunReadinessEvaluating,
        prefixManager: any PrefixManaging,
        steamInstallService: any SteamInstallServicing,
        experimentalLaunchPolicy: ExperimentalLaunchPolicy = .disabled,
        experimentalRunReadinessEvaluator: (any RunReadinessEvaluating)? = nil,
        gameLauncher: (any GameLaunching)? = nil,
        appSupportURL: URL = FileManager.default.temporaryDirectory
            .appending(path: "MacPlayLauncher", directoryHint: .isDirectory)
    ) {
        self.profileManager = profileManager
        self.bundledProfileLoader = bundledProfileLoader
        self.fileSelectionService = fileSelectionService
        self.bookmarkManager = bookmarkManager
        self.gameFolderDetector = gameFolderDetector
        self.dependencyDiagnosticService = dependencyDiagnosticService
        self.diagnosticActivationPolicy = diagnosticActivationPolicy
        self.runReadinessEvaluator = runReadinessEvaluator
        self.prefixManager = prefixManager
        self.steamInstallService = steamInstallService
        self.experimentalLaunchPolicy = experimentalLaunchPolicy
        self.experimentalRunReadinessEvaluator = experimentalRunReadinessEvaluator ?? runReadinessEvaluator
        self.gameLauncher = gameLauncher ?? DisabledGameLauncher()
        self.appSupportURL = appSupportURL
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
        let bookmarkManager = BookmarkManager()
        let prefixManager = PrefixManager(appSupportURL: appSupportURL, fileSystem: fileSystem)
        let gameLauncher = DefaultGameLauncher(
            planner: DefaultGameLaunchPlanner(
                bookmarkManager: bookmarkManager,
                prefixManager: prefixManager
            ),
            executor: ProcessGameLaunchExecutor(),
            accessManager: SecurityScopedAccessManager()
        )
        return AppEnvironment(
            profileManager: GameProfileManager(store: store),
            bundledProfileLoader: BundledGameProfileLoader(),
            fileSelectionService: FileSelectionService(),
            bookmarkManager: bookmarkManager,
            gameFolderDetector: GameFolderDetector(fileSystem: fileSystem),
            dependencyDiagnosticService: SelectableDependencyDiagnosticService(
                mode: .staticOnly,
                policy: .production
            ),
            diagnosticActivationPolicy: .production,
            runReadinessEvaluator: DefaultRunReadinessEvaluator(),
            prefixManager: prefixManager,
            steamInstallService: SteamInstallService(),
            experimentalLaunchPolicy: .experimental,
            experimentalRunReadinessEvaluator: ExperimentalRunReadinessEvaluator(
                prefixManager: prefixManager,
                policy: .experimental
            ),
            gameLauncher: gameLauncher,
            appSupportURL: appSupportURL
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
            runReadinessEvaluator: live.runReadinessEvaluator,
            prefixManager: live.prefixManager,
            steamInstallService: live.steamInstallService,
            experimentalLaunchPolicy: live.experimentalLaunchPolicy,
            experimentalRunReadinessEvaluator: live.experimentalRunReadinessEvaluator,
            gameLauncher: live.gameLauncher,
            appSupportURL: live.appSupportURL
        )
    }
}
