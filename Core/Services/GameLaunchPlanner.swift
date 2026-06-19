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
        guard let executableBookmarkData = profile.executableBookmarkData,
              let workingDirectoryBookmarkData = profile.workingDirectoryBookmarkData else {
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
        let workingDirectoryURL = try bookmarkManager.resolveBookmark(workingDirectoryBookmarkData)

        try PathContainmentValidator.validateExecutable(executableURL, isInside: workingDirectoryURL)
        try validateLaunchArguments(profile.launchArguments)

        let arguments = profile.launchArguments + [executableURL.path]
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

    private func makeCrossOverLaunchPlan(for profile: GameProfile) throws -> GameLaunchPlan {
        guard let bottleName = profile.crossOverBottleName, !bottleName.isEmpty else {
            throw MacPlayError.launchPreparationFailed
        }

        guard let cxstartURL = crossOverResolver.resolve() else {
            throw MacPlayError.crossOverNotFound
        }

        try validateLaunchArguments(profile.launchArguments)

        var arguments = ["--bottle", bottleName]
        if let workingDirectoryBookmarkData = profile.workingDirectoryBookmarkData,
           let workingDirectoryURL = try? bookmarkManager.resolveBookmark(workingDirectoryBookmarkData) {
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
