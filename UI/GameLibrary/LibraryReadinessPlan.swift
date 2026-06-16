import Foundation

enum LibraryReadinessAction: Equatable, Sendable {
    case addGame
    case openDiagnostics
}

struct LibraryReadinessStep: Identifiable, Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case complete
        case needsAction
        case blocked
    }

    let id: String
    let title: String
    let message: String
    let status: Status
    let actionTitle: String?
    let action: LibraryReadinessAction?
}

struct LibraryReadinessPlan: Equatable, Sendable {
    let title: String
    let message: String
    let statusTitle: String
    let isReady: Bool
    let steps: [LibraryReadinessStep]
}

enum LibraryReadinessPlanner {
    static func make(
        profiles: [GameProfile],
        diagnosticSummary: RuntimeDiagnosticSummary?,
        readinessResult _: RunReadinessResult?,
        experimentalReadinessResult: RunReadinessResult?,
        prefixState: PrefixDirectoryState?
    ) -> LibraryReadinessPlan {
        let hasUserProfile = profiles.contains(where: GameProfileDisplayFormatter.isUserConfigured)
        let hasRealSystemCheck = diagnosticSummary?.source == .realSystemCheck
        let wineReady = diagnosticSummary?.dependencies.contains { dependency in
            dependency.kind == .wine && dependency.status == .ready
        } == true
        let experimentalReady = experimentalReadinessResult?.canLaunch == true

        let steps = [
            gameFolderStep(hasUserProfile: hasUserProfile),
            realSystemCheckStep(hasRealSystemCheck: hasRealSystemCheck),
            wineStep(hasRealSystemCheck: hasRealSystemCheck, wineReady: wineReady),
            prefixStep(prefixState: prefixState, hasUserProfile: hasUserProfile),
            experimentalStep(
                experimentalReadinessResult: experimentalReadinessResult,
                experimentalReady: experimentalReady
            )
        ]

        let firstOpenStep = steps.first { $0.status != .complete }
        return LibraryReadinessPlan(
            title: String(localized: "library.readinessPlan.title"),
            message: firstOpenStep?.message ?? String(localized: "library.readinessPlan.readyMessage"),
            statusTitle: experimentalReady
                ? String(localized: "library.readinessPlan.readyStatus")
                : String(localized: "library.readinessPlan.notReadyStatus"),
            isReady: experimentalReady,
            steps: steps
        )
    }

    private static func gameFolderStep(hasUserProfile: Bool) -> LibraryReadinessStep {
        LibraryReadinessStep(
            id: "game-folder",
            title: String(localized: "library.readinessStep.gameFolder.title"),
            message: hasUserProfile
                ? String(localized: "library.readinessStep.gameFolder.done")
                : String(localized: "library.readinessStep.gameFolder.missing"),
            status: hasUserProfile ? .complete : .needsAction,
            actionTitle: hasUserProfile ? nil : String(localized: "library.readinessAction.addGame"),
            action: hasUserProfile ? nil : .addGame
        )
    }

    private static func realSystemCheckStep(hasRealSystemCheck: Bool) -> LibraryReadinessStep {
        LibraryReadinessStep(
            id: "real-system-check",
            title: String(localized: "library.readinessStep.realCheck.title"),
            message: hasRealSystemCheck
                ? String(localized: "library.readinessStep.realCheck.done")
                : String(localized: "library.readinessStep.realCheck.missing"),
            status: hasRealSystemCheck ? .complete : .needsAction,
            actionTitle: hasRealSystemCheck ? nil : String(localized: "library.readinessAction.realCheck"),
            action: hasRealSystemCheck ? nil : .openDiagnostics
        )
    }

    private static func wineStep(hasRealSystemCheck: Bool, wineReady: Bool) -> LibraryReadinessStep {
        let status: LibraryReadinessStep.Status
        let message: String

        if wineReady {
            status = .complete
            message = String(localized: "library.readinessStep.wine.done")
        } else if hasRealSystemCheck {
            status = .blocked
            message = String(localized: "library.readinessStep.wine.missing")
        } else {
            status = .needsAction
            message = String(localized: "library.readinessStep.wine.needsCheck")
        }

        return LibraryReadinessStep(
            id: "wine",
            title: String(localized: "library.readinessStep.wine.title"),
            message: message,
            status: status,
            actionTitle: wineReady ? nil : String(localized: "library.readinessAction.openDiagnostics"),
            action: wineReady ? nil : .openDiagnostics
        )
    }

    private static func prefixStep(
        prefixState: PrefixDirectoryState?,
        hasUserProfile: Bool
    ) -> LibraryReadinessStep {
        let prefixExists = prefixState?.availability == .exists
        let canCreatePrefix = hasUserProfile && !prefixExists

        return LibraryReadinessStep(
            id: "prefix",
            title: String(localized: "library.readinessStep.prefix.title"),
            message: prefixExists
                ? String(localized: "library.readinessStep.prefix.done")
                : String(localized: "library.readinessStep.prefix.missing"),
            status: prefixExists ? .complete : (canCreatePrefix ? .needsAction : .blocked),
            actionTitle: prefixExists ? nil : String(localized: "library.readinessAction.createPrefix"),
            action: prefixExists ? nil : .openDiagnostics
        )
    }

    private static func experimentalStep(
        experimentalReadinessResult: RunReadinessResult?,
        experimentalReady: Bool
    ) -> LibraryReadinessStep {
        LibraryReadinessStep(
            id: "experimental-launch",
            title: String(localized: "library.readinessStep.experimental.title"),
            message: experimentalReady
                ? String(localized: "library.readinessStep.experimental.done")
                : experimentalBlockerMessage(from: experimentalReadinessResult),
            status: experimentalReady ? .complete : .blocked,
            actionTitle: String(localized: "library.readinessAction.experimentalLaunch"),
            action: .openDiagnostics
        )
    }

    private static func experimentalBlockerMessage(from result: RunReadinessResult?) -> String {
        guard let firstBlocker = result?.blockers.first else {
            return String(localized: "library.readinessStep.experimental.missing")
        }

        return firstBlocker.message
    }
}
