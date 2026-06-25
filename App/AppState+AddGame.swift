import Foundation

@MainActor
extension AppState {
    var canSaveAddGameProfile: Bool {
        guard addGameForm.selectedFolderURL != nil,
              !addGameForm.gameName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        if addGameForm.isCrossOver { return true }
        return addGameForm.selectedExecutableURL != nil
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
                let template = loadBundledCossacks3Profile()
                addGameForm.gameName = detectedGame.displayName
                addGameForm.detectedRuntime = template.runtime
                if template.runtime == .crossOver {
                    addGameForm.selectedExecutableURL = nil
                } else {
                    addGameForm.selectedExecutableURL = detectedGame.executableURL
                }
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

        guard executableURL.pathExtension.lowercased() == "exe" else {
            addGameForm.selectedExecutableURL = nil
            addGameForm.errorMessage = "Sadece .exe uzantılı Windows çalıştırılabilir dosyaları desteklenmektedir."
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

    func makeAddGameProfile() throws -> GameProfile {
        guard let folderURL = addGameForm.selectedFolderURL else {
            throw MacPlayError.invalidPath
        }

        let displayName = addGameForm.gameName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !displayName.isEmpty else {
            throw MacPlayError.invalidPath
        }

        let profileID = makeProfileID(displayName: displayName)
        let template = loadBundledCossacks3Profile()

        if template.runtime == .crossOver {
            return try makeCrossOverProfile(
                profileID: profileID,
                displayName: displayName,
                folderURL: folderURL,
                template: template
            )
        }

        guard let executableURL = addGameForm.selectedExecutableURL else {
            throw MacPlayError.invalidPath
        }

        try PathContainmentValidator.validateExecutable(executableURL, isInside: folderURL)

        return try makeStandardProfile(
            profileID: profileID,
            displayName: displayName,
            folderURL: folderURL,
            executableURL: executableURL,
            template: template
        )
    }

    private func makeCrossOverProfile(
        profileID: String,
        displayName: String,
        folderURL: URL,
        template: GameProfile
    ) throws -> GameProfile {
        GameProfile(
            schemaVersion: template.schemaVersion,
            id: profileID,
            displayName: displayName,
            executablePath: nil,
            workingDirectory: folderURL.standardizedFileURL.path,
            prefixPath: "Prefixes/\(profileID)",
            executableBookmarkData: nil,
            workingDirectoryBookmarkData: try environment.bookmarkManager.createBookmark(for: folderURL),
            runtime: template.runtime,
            crossOverBottleName: template.crossOverBottleName,
            performanceMode: template.performanceMode,
            wineArch: template.wineArch,
            windowsVersion: template.windowsVersion,
            dependencies: template.dependencies,
            environment: template.environment,
            launchArguments: template.launchArguments,
            knownIssues: template.knownIssues,
            requiresWineSteam: template.requiresWineSteam,
            lastPlayedAt: nil,
            totalPlayTimeMinutes: 0,
            launchCount: 0
        )
    }

    private func makeStandardProfile(
        profileID: String,
        displayName: String,
        folderURL: URL,
        executableURL: URL,
        template: GameProfile
    ) throws -> GameProfile {
        GameProfile(
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
            requiresWineSteam: template.requiresWineSteam,
            lastPlayedAt: nil,
            totalPlayTimeMinutes: 0,
            launchCount: 0
        )
    }

    func makeProfileID(displayName: String) -> String {
        let sanitizedName = PathSanitizer.fileName(displayName.lowercased())
        let suffix = UUID().uuidString.prefix(8).lowercased()
        return "\(sanitizedName)-\(suffix)"
    }
}
