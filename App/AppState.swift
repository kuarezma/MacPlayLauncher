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
            resetDiagnosticsSessionToStaticPreparation()
        } catch {
            addGameForm.errorMessage = ErrorPresenter.message(for: error)
        }
    }

    func cancelAddGame() {
        addGameForm = AddGameFormState()
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
}
