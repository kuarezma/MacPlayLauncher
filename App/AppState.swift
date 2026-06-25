import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    struct AddGameFormState: Equatable {
        var selectedFolderURL: URL?
        var selectedExecutableURL: URL?
        var gameName = ""
        var detectedRuntime: RuntimeKind?
        var detectionStatusMessage: String?
        var errorMessage: String?
        var successMessage: String?

        var isCrossOver: Bool { detectedRuntime == .crossOver }
    }

    enum NavigationItem: Hashable {
        case library
        case addGame
        case diagnostics
        case settings
        case setup
    }

    var selectedNavigationItem: NavigationItem? = .library
    var selectedProfileID: String?
    var profiles: [GameProfile] = []
    var loadErrorMessage: String?
    var launchingProfileID: String?
    var launchErrorMessage: String?
    var addGameForm = AddGameFormState()
    var steamInstallInput = ""
    var steamInstallMessage: String?
    var steamInstallErrorMessage: String?
    var diagnosticsDisplayMode: DiagnosticMode = .staticOnly
    var cachedDiagnosticSummary: RuntimeDiagnosticSummary?
    var cachedReadinessResult: RunReadinessResult?
    var setupSteps: [SetupStep] = []
    var isRefreshingSetup = false
    var setupActionMessage: String?
    var setupPatchErrorMessage: String?
    var setupStatusOverrides: [String: SetupStepStatus] = [:]
    private(set) var setupOrchestrator: SetupOrchestrator?

    let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
        self.setupOrchestrator = SetupOrchestrator(
            setupService: environment.cossacksSetupService,
            installerService: environment.setupInstallerService
        )
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

    func loadBundledCossacks3Profile() -> GameProfile {
        do {
            return try environment.bundledProfileLoader.loadCossacks3Profile()
        } catch {
            loadErrorMessage = ErrorPresenter.message(for: error)
            return .sampleCossacks3
        }
    }

    var prefixTargetProfile: GameProfile? {
        if let selectedProfileID,
           let selected = profiles.first(where: { $0.id == selectedProfileID }) {
            return selected
        }

        return profiles.first
    }

    var appDataFolderPath: String {
        environment.appSupportURL.path
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
