import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    struct AddGameFormState: Equatable {
        var selectedFolderURL: URL?
        var selectedExecutableURL: URL?
        var gameName = ""
        var detectionStatusMessage: String?
        var errorMessage: String?
        var successMessage: String?
    }

    enum NavigationItem: Hashable {
        case library
        case addGame
        case diagnostics
        case settings
    }

    var selectedNavigationItem: NavigationItem? = .library
    var selectedProfileID: String?
    var profiles: [GameProfile] = []
    var loadErrorMessage: String?
    var addGameForm = AddGameFormState()
    var steamInstallInput = ""
    var steamInstallMessage: String?
    var steamInstallErrorMessage: String?
    private(set) var diagnosticsDisplayMode: DiagnosticMode = .staticOnly
    private(set) var cachedDiagnosticSummary: RuntimeDiagnosticSummary?
    private(set) var cachedReadinessResult: RunReadinessResult?

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func loadInitialProfiles() async {
        do {
            profiles = try environment.profileManager.loadProfiles()
            if profiles.isEmpty {
                profiles = [loadBundledCossacks3Profile()]
            }
            selectedProfileID = profiles.first?.id
        } catch {
            loadErrorMessage = ErrorPresenter.message(for: error)
            profiles = [loadBundledCossacks3Profile()]
            selectedProfileID = profiles.first?.id
        }
    }

    private func loadBundledCossacks3Profile() -> GameProfile {
        do {
            return try environment.bundledProfileLoader.loadCossacks3Profile()
        } catch {
            loadErrorMessage = ErrorPresenter.message(for: error)
            return .sampleCossacks3
        }
    }

    var canSaveAddGameProfile: Bool {
        addGameForm.selectedFolderURL != nil
            && addGameForm.selectedExecutableURL != nil
            && !addGameForm.gameName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func selectGameFolderForAddGame() {
        guard let folderURL = environment.fileSelectionService.selectGameFolder() else {
            return
        }

        addGameForm.selectedFolderURL = folderURL
        addGameForm.selectedExecutableURL = nil
        addGameForm.errorMessage = nil
        addGameForm.successMessage = nil

        if addGameForm.gameName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addGameForm.gameName = folderURL.lastPathComponent
        }

        do {
            if let detectedGame = try environment.gameFolderDetector.detectCossacks3(in: folderURL) {
                addGameForm.gameName = detectedGame.displayName
                addGameForm.selectedExecutableURL = detectedGame.executableURL
                addGameForm.detectionStatusMessage = String(localized: "addGame.detection.cossacks3")
            } else {
                addGameForm.detectionStatusMessage = String(localized: "addGame.detection.notFound")
            }
        } catch {
            addGameForm.detectionStatusMessage = nil
            addGameForm.errorMessage = ErrorPresenter.message(for: error)
        }
    }

    func selectExecutableForAddGame() {
        guard let folderURL = addGameForm.selectedFolderURL else {
            addGameForm.errorMessage = String(localized: "addGame.error.selectFolderFirst")
            return
        }

        guard let executableURL = environment.fileSelectionService.selectExecutableFile() else {
            return
        }

        do {
            try PathContainmentValidator.validateExecutable(executableURL, isInside: folderURL)
            addGameForm.selectedExecutableURL = executableURL
            addGameForm.errorMessage = nil
            addGameForm.successMessage = nil
        } catch {
            addGameForm.selectedExecutableURL = nil
            addGameForm.errorMessage = ErrorPresenter.message(for: error)
        }
    }

    func saveAddGameProfile() {
        do {
            let profile = try makeAddGameProfile()
            try environment.profileManager.saveProfile(profile)
            profiles = try environment.profileManager.loadProfiles()
            selectedProfileID = profile.id
            selectedNavigationItem = .library
            addGameForm = AddGameFormState(successMessage: String(localized: "addGame.save.success"))
            steamInstallInput = ""
            steamInstallMessage = nil
            steamInstallErrorMessage = nil
            resetDiagnosticsSessionToStaticPreparation()
        } catch {
            addGameForm.errorMessage = ErrorPresenter.message(for: error)
        }
    }

    func cancelAddGame() {
        addGameForm = AddGameFormState()
        steamInstallInput = ""
        steamInstallMessage = nil
        steamInstallErrorMessage = nil
        selectedNavigationItem = .library
    }

    var canRunManualRealDiagnosticCheck: Bool {
        guard let policy = environment.diagnosticActivationPolicy else {
            return false
        }

        return policy.allowsRealDiagnostics && policy.requiresExplicitUserAction
    }

    func loadRuntimeDiagnosticSummary(mode: DiagnosticMode = .staticOnly) async -> RuntimeDiagnosticSummary {
        if let modeAware = environment.dependencyDiagnosticService as? any ModeAwareDependencyDiagnosticServicing {
            return await modeAware.loadSummary(profiles: profiles, mode: mode)
        }

        return await environment.dependencyDiagnosticService.loadSummary(profiles: profiles)
    }

    func evaluateRunReadiness(diagnosticSummary: RuntimeDiagnosticSummary) -> RunReadinessResult {
        environment.runReadinessEvaluator.evaluate(
            profiles: profiles,
            diagnosticSummary: diagnosticSummary
        )
    }

    func evaluateExperimentalRunReadiness(diagnosticSummary: RuntimeDiagnosticSummary) -> RunReadinessResult {
        environment.experimentalRunReadinessEvaluator.evaluate(
            profiles: profiles,
            diagnosticSummary: diagnosticSummary
        )
    }

    var isExperimentalLaunchEnabled: Bool {
        environment.experimentalLaunchPolicy.isEnabled
    }

    var experimentalLaunchStatusLabel: String {
        isExperimentalLaunchEnabled
            ? String(localized: "settings.experimentalLaunch.enabled")
            : String(localized: "settings.experimentalLaunch.disabled")
    }

    var appDataFolderPath: String {
        environment.appSupportURL.path
    }

    func launchExperimentalGame() throws -> GameLaunchResult {
        guard environment.experimentalLaunchPolicy.isEnabled else {
            throw MacPlayError.launchPreparationFailed
        }

        guard let profile = prefixTargetProfile else {
            throw MacPlayError.profileNotFound
        }

        return try environment.gameLauncher.launch(profile: profile)
    }

    func restoreCachedDiagnosticsIfAvailable() -> (summary: RuntimeDiagnosticSummary, readinessResult: RunReadinessResult)? {
        guard diagnosticsDisplayMode == .realReadOnly,
              let summary = cachedDiagnosticSummary,
              let readinessResult = cachedReadinessResult,
              summary.source == .realSystemCheck else {
            return nil
        }

        return (summary, readinessResult)
    }

    func storeDiagnosticsSession(
        mode: DiagnosticMode,
        summary: RuntimeDiagnosticSummary,
        readinessResult: RunReadinessResult
    ) {
        diagnosticsDisplayMode = mode
        cachedDiagnosticSummary = summary
        cachedReadinessResult = readinessResult
    }

    func resetDiagnosticsSessionToStaticPreparation() {
        diagnosticsDisplayMode = .staticOnly
        cachedDiagnosticSummary = nil
        cachedReadinessResult = nil
    }

    func libraryReadinessResult() async -> RunReadinessResult {
        if let cached = restoreCachedDiagnosticsIfAvailable() {
            return cached.readinessResult
        }

        let summary = await loadRuntimeDiagnosticSummary(mode: .staticOnly)
        return evaluateRunReadiness(diagnosticSummary: summary)
    }

    var diagnosticsSessionSourceLabel: String {
        switch cachedDiagnosticSummary?.source {
        case .realSystemCheck:
            return String(localized: "diagnostics.source.real.title")
        case .staticPreparation, .none:
            return String(localized: "diagnostics.source.static.title")
        }
    }

    var prefixTargetProfile: GameProfile? {
        if let selectedProfileID,
           let selected = profiles.first(where: { $0.id == selectedProfileID }) {
            return selected
        }

        return profiles.first
    }

    func loadPrefixDirectoryState() throws -> PrefixDirectoryState? {
        guard let profile = prefixTargetProfile else {
            return nil
        }

        return try environment.prefixManager.directoryState(for: profile)
    }

    func createPrefixDirectory() throws -> PrefixDirectoryState {
        guard let profile = prefixTargetProfile else {
            throw MacPlayError.profileNotFound
        }

        return try environment.prefixManager.createPrefixDirectory(for: profile)
    }

    private func makeAddGameProfile() throws -> GameProfile {
        guard let folderURL = addGameForm.selectedFolderURL,
              let executableURL = addGameForm.selectedExecutableURL else {
            throw MacPlayError.invalidPath
        }

        try PathContainmentValidator.validateExecutable(executableURL, isInside: folderURL)

        let displayName = addGameForm.gameName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !displayName.isEmpty else {
            throw MacPlayError.invalidPath
        }

        let profileID = makeProfileID(displayName: displayName)
        let template = loadBundledCossacks3Profile()
        return GameProfile(
            schemaVersion: template.schemaVersion,
            id: profileID,
            displayName: displayName,
            executablePath: executableURL.standardizedFileURL.path,
            workingDirectory: folderURL.standardizedFileURL.path,
            prefixPath: "Prefixes/\(profileID)",
            executableBookmarkData: try environment.bookmarkManager.createBookmark(for: executableURL),
            workingDirectoryBookmarkData: try environment.bookmarkManager.createBookmark(for: folderURL),
            runtime: template.runtime,
            performanceMode: template.performanceMode,
            wineArch: template.wineArch,
            windowsVersion: template.windowsVersion,
            dependencies: template.dependencies,
            environment: template.environment,
            launchArguments: template.launchArguments,
            knownIssues: template.knownIssues,
            lastPlayedAt: nil,
            totalPlayTimeMinutes: 0,
            launchCount: 0
        )
    }

    private func makeProfileID(displayName: String) -> String {
        let sanitizedName = PathSanitizer.fileName(displayName.lowercased())
        let suffix = UUID().uuidString.prefix(8).lowercased()
        return "\(sanitizedName)-\(suffix)"
    }

    func showAddGame() {
        selectedNavigationItem = .addGame
    }

    func showDiagnostics() {
        selectedNavigationItem = .diagnostics
    }

    func showSettings() {
        selectedNavigationItem = .settings
    }

    func openSteamInstall() {
        steamInstallMessage = nil
        steamInstallErrorMessage = nil

        let input = steamInstallInput.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if input.isEmpty {
                try environment.steamInstallService.openLibrary()
                steamInstallMessage = String(localized: "steam_open_success_library")
            } else if let appID = extractAppID(from: input) {
                try environment.steamInstallService.openInstallPage(for: appID)
                steamInstallMessage = String(localized: "steam_open_success_install")
            } else {
                steamInstallErrorMessage = String(localized: "addGame.steam.error.invalidInput")
            }
        } catch SteamInstallError.appNotFound {
            steamInstallErrorMessage = String(localized: "steam_not_installed")
        } catch {
            steamInstallErrorMessage = String(localized: "steam_open_failed")
        }
    }

    private func extractAppID(from input: String) -> String? {
        if input.allSatisfy(\.isNumber) && !input.isEmpty {
            return input
        }

        if input.hasPrefix("steam://install/") {
            let appID = input.replacingOccurrences(of: "steam://install/", with: "")
            if appID.allSatisfy(\.isNumber) && !appID.isEmpty {
                return appID
            }
        }

        if let url = URL(string: input), url.host == "store.steampowered.com" {
            let pathComponents = url.pathComponents
            if let appIndex = pathComponents.firstIndex(of: "app"), appIndex + 1 < pathComponents.count {
                let appID = pathComponents[appIndex + 1]
                if appID.allSatisfy(\.isNumber) && !appID.isEmpty {
                    return appID
                }
            }
        }

        return nil
    }
}
