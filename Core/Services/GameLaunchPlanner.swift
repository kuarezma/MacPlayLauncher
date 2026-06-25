import Foundation

protocol GameLaunchPlanning: Sendable {
    func makeLaunchPlan(for profile: GameProfile) throws -> GameLaunchPlan
}

struct DefaultGameLaunchPlanner: GameLaunchPlanning {
    private let bookmarkManager: any BookmarkManaging
    private let prefixManager: any PrefixManaging
    private let wineResolver: WineExecutableResolver
    private let crossOverResolver: CrossOverExecutableResolver

    init(
        bookmarkManager: any BookmarkManaging,
        prefixManager: any PrefixManaging,
        wineResolver: WineExecutableResolver = WineExecutableResolver(),
        crossOverResolver: CrossOverExecutableResolver = CrossOverExecutableResolver()
    ) {
        self.bookmarkManager = bookmarkManager
        self.prefixManager = prefixManager
        self.wineResolver = wineResolver
        self.crossOverResolver = crossOverResolver
    }

    func makeLaunchPlan(for profile: GameProfile) throws -> GameLaunchPlan {
        if profile.runtime == .crossOver {
            return try makeCrossOverLaunchPlan(for: profile)
        }
        return try makeWineLaunchPlan(for: profile)
    }

    private func makeWineLaunchPlan(for profile: GameProfile) throws -> GameLaunchPlan {
        guard let executableBookmarkData = profile.executableBookmarkData else {
            throw MacPlayError.launchPreparationFailed
        }

        let prefixState = try prefixManager.directoryState(for: profile)
        guard prefixState.availability == .exists else {
            throw MacPlayError.prefixDirectoryMissing
        }

        guard let wineURL = wineResolver.resolve() else {
            throw MacPlayError.wineNotFound
        }

        let executableURL = try bookmarkManager.resolveBookmark(executableBookmarkData)
        let workingDirectoryURL = resolveWineWorkingDirectory(
            profile: profile,
            executableURL: executableURL
        )

        try PathContainmentValidator.validateExecutable(executableURL, isInside: workingDirectoryURL)
        try validateLaunchArguments(profile.launchArguments)

        let executablePath = executableURL.path
        let arguments = profile.launchArguments.filter { $0 != executablePath } + [executablePath]
        let environment = LaunchEnvironmentBuilder.make(
            profile: profile,
            winePrefix: prefixState.absolutePath
        )

        return GameLaunchPlan(
            profileID: profile.id,
            wineURL: wineURL,
            arguments: arguments,
            environment: environment,
            executableURL: executableURL,
            workingDirectoryURL: workingDirectoryURL
        )
    }

    private func resolveWineWorkingDirectory(profile: GameProfile, executableURL: URL) -> URL {
        if let data = profile.workingDirectoryBookmarkData,
           let resolved = try? bookmarkManager.resolveBookmark(data) {
            return resolved
        }

        if let workingDirectory = profile.workingDirectory?.trimmingCharacters(in: .whitespacesAndNewlines),
           !workingDirectory.isEmpty {
            let expanded = (workingDirectory as NSString).expandingTildeInPath
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: expanded, isDirectory: &isDirectory),
               isDirectory.boolValue {
                return URL(fileURLWithPath: expanded, isDirectory: true)
            }
        }

        return executableURL.deletingLastPathComponent()
    }

    private func makeCrossOverLaunchPlan(for profile: GameProfile) throws -> GameLaunchPlan {
        guard let bottleName = profile.crossOverBottleName, !bottleName.isEmpty else {
            throw MacPlayError.launchPreparationFailed
        }

        guard let cxstartURL = crossOverResolver.resolve() else {
            throw MacPlayError.crossOverNotFound
        }

        try validateLaunchArguments(profile.launchArguments)

        var arguments = ["--bottle", bottleName]
        if let workingDirectoryURL = crossOverWorkingDirectoryURL(for: profile) {
            arguments += ["--workdir", workingDirectoryURL.path]
        }
        for (key, value) in profile.environment.sorted(by: { $0.key < $1.key }) {
            arguments += ["--env", "\(key)=\(value)"]
        }
        arguments += profile.launchArguments

        var environment = ProcessInfo.processInfo.environment
        environment["CX_ROOT"] = "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver"

        return GameLaunchPlan(
            profileID: profile.id,
            wineURL: cxstartURL,
            arguments: arguments,
            environment: environment,
            executableURL: cxstartURL,
            workingDirectoryURL: nil
        )
    }

    private func crossOverWorkingDirectoryURL(for profile: GameProfile) -> URL? {
        if let workingDirectoryBookmarkData = profile.workingDirectoryBookmarkData,
           let workingDirectoryURL = try? bookmarkManager.resolveBookmark(workingDirectoryBookmarkData) {
            return workingDirectoryURL
        }

        guard let workingDirectory = profile.workingDirectory?.trimmingCharacters(in: .whitespacesAndNewlines),
              !workingDirectory.isEmpty else {
            return nil
        }

        let expandedPath = (workingDirectory as NSString).expandingTildeInPath
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: expandedPath, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return nil
        }

        return URL(fileURLWithPath: expandedPath, isDirectory: true)
    }

    private func validateLaunchArguments(_ arguments: [String]) throws {
        guard !arguments.contains("-c") else {
            throw MacPlayError.launchPreparationFailed
        }
    }
}

enum LaunchEnvironmentBuilder {
    static func make(profile: GameProfile, winePrefix: String) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        for (key, value) in profile.environment {
            environment[key] = value
        }
        environment["WINEPREFIX"] = winePrefix
        environment["WINEARCH"] = profile.wineArch.rawValue
        return environment
    }
}
