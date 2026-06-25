import Foundation

struct ExperimentalRunReadinessEvaluator: RunReadinessEvaluating {
    private let baseEvaluator: DefaultRunReadinessEvaluator
    private let prefixManager: any PrefixManaging
    private let wineResolver: WineExecutableResolver
    private let policy: ExperimentalLaunchPolicy

    init(
        prefixManager: any PrefixManaging,
        policy: ExperimentalLaunchPolicy,
        wineResolver: WineExecutableResolver = WineExecutableResolver()
    ) {
        self.baseEvaluator = DefaultRunReadinessEvaluator()
        self.prefixManager = prefixManager
        self.wineResolver = wineResolver
        self.policy = policy
    }

    func evaluate(
        profiles: [GameProfile],
        diagnosticSummary: RuntimeDiagnosticSummary
    ) -> RunReadinessResult {
        let base = baseEvaluator.evaluate(
            profiles: profiles,
            diagnosticSummary: diagnosticSummary
        )

        guard policy.isEnabled else {
            return base
        }

        // CrossOver profiles can be validated directly — no realSystemCheck needed
        if let crossOverProfile = profiles.first(where: {
            RuntimeDependencyFactory.isConfiguredProfile($0) && $0.runtime == .crossOver
        }) {
            return evaluateCrossOver(profile: crossOverProfile, base: base)
        }

        guard let profile = profiles.first(where: RuntimeDependencyFactory.isConfiguredProfile) else {
            return base
        }

        guard diagnosticSummary.source == .realSystemCheck else {
            return blockedResult(
                base: base,
                blocker: experimentalBlocker(
                    id: "experimental.requiresRealDiagnostics",
                    title: String(localized: "readiness.experimental.requiresRealDiagnostics.title"),
                    message: String(localized: "readiness.experimental.requiresRealDiagnostics.message"),
                    suggestedAction: String(localized: "readiness.experimental.requiresRealDiagnostics.action")
                )
            )
        }

        let blockers = collectBlockers(profile: profile, base: base, diagnosticSummary: diagnosticSummary)
        let blocking = blockers.filter { $0.severity == .blocking }

        guard blocking.isEmpty else {
            return RunReadinessResult(
                status: .blocked,
                title: String(localized: "readiness.experimental.blocked.title"),
                message: String(localized: "readiness.experimental.blocked.message"),
                blockers: blockers,
                canLaunch: false
            )
        }

        return RunReadinessResult(
            status: .ready,
            title: String(localized: "readiness.experimental.ready.title"),
            message: String(localized: "readiness.experimental.ready.message"),
            blockers: blockers,
            canLaunch: true
        )
    }

    private func collectBlockers(
        profile: GameProfile,
        base: RunReadinessResult,
        diagnosticSummary: RuntimeDiagnosticSummary
    ) -> [RunReadinessBlocker] {
        var blockers = base.blockers.filter { $0.source != .runtimeDependency || isExperimentalRelevant($0.id) }

        if let prefixBlocker = makePrefixBlocker(for: profile) {
            blockers.append(prefixBlocker)
        }

        if profile.runtime != .crossOver {
            blockers += wineBlockers(diagnosticSummary: diagnosticSummary)
        }

        if let rosettaBlocker = rosettaBlocker(diagnosticSummary: diagnosticSummary) {
            blockers.append(rosettaBlocker)
        }

        return blockers
    }

    private func wineBlockers(diagnosticSummary: RuntimeDiagnosticSummary) -> [RunReadinessBlocker] {
        if dependency(diagnosticSummary, kind: .wine)?.status != .ready {
            return [experimentalBlocker(
                id: "experimental.wine.notReady",
                title: String(localized: "readiness.experimental.wineMissing.title"),
                message: String(localized: "readiness.experimental.wineMissing.message"),
                suggestedAction: String(localized: "readiness.experimental.wineMissing.action")
            )]
        } else if wineResolver.resolve() == nil {
            return [experimentalBlocker(
                id: "experimental.wine.missing",
                title: String(localized: "readiness.experimental.wineMissing.title"),
                message: String(localized: "readiness.experimental.wineMissing.message"),
                suggestedAction: String(localized: "readiness.experimental.wineMissing.action")
            )]
        }
        return []
    }

    private func rosettaBlocker(diagnosticSummary: RuntimeDiagnosticSummary) -> RunReadinessBlocker? {
        guard let rosetta = dependency(diagnosticSummary, kind: .rosetta),
              rosetta.status == .missing || rosetta.status == .unsupported else {
            return nil
        }

        return experimentalBlocker(
            id: "experimental.rosetta.blocked",
            title: "\(String(localized: "readiness.missingRuntimeDependency.title")): Rosetta",
            message: rosetta.userFacingDescription,
            suggestedAction: rosetta.suggestedAction ?? String(localized: "readiness.fixMissingBeforeLaunch")
        )
    }

    private func evaluateCrossOver(profile: GameProfile, base: RunReadinessResult) -> RunReadinessResult {
        let crossOverResolver = CrossOverExecutableResolver()
        guard crossOverResolver.resolve() != nil else {
            return blockedResult(
                base: base,
                blocker: experimentalBlocker(
                    id: "experimental.crossover.missing",
                    title: String(localized: "readiness.experimental.crossoverMissing.title"),
                    message: String(localized: "readiness.experimental.crossoverMissing.message"),
                    suggestedAction: String(localized: "readiness.experimental.crossoverMissing.action")
                )
            )
        }

        return RunReadinessResult(
            status: .ready,
            title: String(localized: "readiness.experimental.ready.title"),
            message: String(localized: "readiness.experimental.ready.message"),
            blockers: [],
            canLaunch: true
        )
    }

    private func dependency(_ summary: RuntimeDiagnosticSummary, kind: RuntimeDependencyKind) -> RuntimeDependency? {
        summary.dependencies.first { $0.kind == kind }
    }

    private func isExperimentalRelevant(_ blockerID: String) -> Bool {
        blockerID.hasPrefix("wine.")
            || blockerID.hasPrefix("rosetta.")
            || blockerID == "game-profile.missing"
    }

    private func makePrefixBlocker(for profile: GameProfile) -> RunReadinessBlocker? {
        guard let prefixState = try? prefixManager.directoryState(for: profile),
              prefixState.availability == .exists else {
            return experimentalBlocker(
                id: "experimental.prefix.missing",
                title: String(localized: "readiness.experimental.prefixMissing.title"),
                message: String(localized: "readiness.experimental.prefixMissing.message"),
                suggestedAction: String(localized: "readiness.experimental.prefixMissing.action")
            )
        }

        return nil
    }

    private func blockedResult(base: RunReadinessResult, blocker: RunReadinessBlocker) -> RunReadinessResult {
        RunReadinessResult(
            status: .blocked,
            title: String(localized: "readiness.experimental.blocked.title"),
            message: String(localized: "readiness.experimental.blocked.message"),
            blockers: base.blockers + [blocker],
            canLaunch: false
        )
    }

    private func experimentalBlocker(
        id: String,
        title: String,
        message: String,
        suggestedAction: String
    ) -> RunReadinessBlocker {
        RunReadinessBlocker(
            id: id,
            title: title,
            message: message,
            severity: .blocking,
            source: .runtimeDependency,
            suggestedAction: suggestedAction,
            isUserActionable: true
        )
    }
}
