import Foundation
import Observation

@MainActor
@Observable
final class AppState {
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

    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func loadInitialProfiles() async {
        do {
            profiles = try environment.profileManager.loadProfiles()
            if profiles.isEmpty {
                profiles = [GameProfile.sampleCossacks3]
            }
            selectedProfileID = profiles.first?.id
        } catch {
            loadErrorMessage = ErrorPresenter.message(for: error)
            profiles = [GameProfile.sampleCossacks3]
            selectedProfileID = profiles.first?.id
        }
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

