import Foundation

@MainActor
extension AppState {
    var isExperimentalLaunchEnabled: Bool {
        environment.experimentalLaunchPolicy.isEnabled
    }

    var experimentalLaunchStatusLabel: String {
        isExperimentalLaunchEnabled
            ? String(localized: "settings.experimentalLaunch.enabled")
            : String(localized: "settings.experimentalLaunch.disabled")
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

    func launchGame(profileID: String) {
        launchingProfileID = profileID
        launchErrorMessage = nil

        guard let profile = profiles.first(where: { $0.id == profileID }) else {
            launchErrorMessage = String(localized: "addGame.error.selectFolderFirst") // Generic fallback
            launchingProfileID = nil
            return
        }

        do {
            let state = try environment.prefixManager.directoryState(for: profile)
            if state.availability != .exists {
                _ = try environment.prefixManager.createPrefixDirectory(for: profile)
            }

            _ = try environment.gameLauncher.launch(profile: profile)

            if let index = profiles.firstIndex(where: { $0.id == profileID }) {
                var updatedProfile = profiles[index]
                updatedProfile.launchCount += 1
                updatedProfile.lastPlayedAt = Date()
                try environment.profileManager.saveProfile(updatedProfile)
                profiles[index] = updatedProfile
            }

            launchingProfileID = nil
        } catch {
            launchErrorMessage = ErrorPresenter.message(for: error)
            launchingProfileID = nil
        }
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
}
