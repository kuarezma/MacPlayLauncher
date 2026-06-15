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
        } catch {
            addGameForm.errorMessage = ErrorPresenter.message(for: error)
        }
    }

    func cancelAddGame() {
        addGameForm = AddGameFormState()
        selectedNavigationItem = .library
    }

    func loadRuntimeDiagnosticSummary() async -> RuntimeDiagnosticSummary {
        await environment.dependencyDiagnosticService.loadSummary(profiles: profiles)
    }

    func evaluateRunReadiness(diagnosticSummary: RuntimeDiagnosticSummary) -> RunReadinessResult {
        environment.runReadinessEvaluator.evaluate(
            profiles: profiles,
            diagnosticSummary: diagnosticSummary
        )
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
