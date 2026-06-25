import Foundation

@MainActor
extension AppState {
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

    func launchGameWithWineSteam(profileID: String) async {
        launchingProfileID = profileID
        launchErrorMessage = nil

        guard let profile = profiles.first(where: { $0.id == profileID }),
              let bottleName = profile.crossOverBottleName else {
            launchingProfileID = nil
            return
        }

        do {
            try await environment.wineSteamService.launch(bottleName: bottleName)
            try await environment.wineSteamService.waitForReadiness(timeout: 30)
            let displayService = environment.displayResolutionService
            await displayService.setGameResolution()
            launchGame(profileID: profileID)
            Task.detached {
                await AppState.monitorGameExitAndRestoreDisplay(service: displayService)
            }
        } catch WineSteamError.readinessTimeout {
            launchErrorMessage = String(localized: "steam_ready_timeout")
            launchingProfileID = nil
        } catch {
            launchErrorMessage = ErrorPresenter.message(for: error)
            launchingProfileID = nil
        }
    }

    func launchGameWithSteamInitiation(profileID: String) async {
        launchingProfileID = profileID
        launchErrorMessage = nil
        steamInstallMessage = nil
        steamInstallErrorMessage = nil

        do {
            try environment.steamInstallService.openLibrary()
            steamInstallMessage = String(localized: "steam_open_success_library")

            try await environment.steamInstallService.waitForReadiness(timeout: 30)

            launchGame(profileID: profileID)
        } catch SteamInstallError.readinessTimeout {
            launchErrorMessage = String(localized: "steam_ready_timeout")
            launchingProfileID = nil
        } catch SteamInstallError.appNotFound {
            launchErrorMessage = String(localized: "steam_not_installed")
            launchingProfileID = nil
        } catch {
            launchErrorMessage = ErrorPresenter.message(for: error)
            launchingProfileID = nil
        }
    }

    private static func monitorGameExitAndRestoreDisplay(service: any DisplayResolutionServicing) async {
        while true {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            let isRunning = await GameProcessMonitor.isProcessRunning(name: "cossacks.exe")
            if !isRunning {
                await service.restoreResolution()
                await GameProcessMonitor.killWineProcesses()
                return
            }
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
