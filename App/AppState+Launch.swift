import Foundation

extension Notification.Name {
    static let gameProcessDidTerminate = Notification.Name("MacPlayGameProcessDidTerminate")
}

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

    func setupGameTerminationObserver() {
        gameTerminationObserver = NotificationCenter.default.addObserver(
            forName: .gameProcessDidTerminate,
            object: nil,
            queue: nil
        ) { [weak self] notification in
            guard let exitCode = notification.userInfo?["exitCode"] as? Int32,
                  exitCode == 53 else { return }
            Task { @MainActor [weak self] in
                self?.launchExitAlertMessage = String(localized: "error.exit53.offlineTxt")
            }
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
