import Foundation

struct DefaultRunReadinessEvaluator: RunReadinessEvaluating {
    func evaluate(
        profiles: [GameProfile],
        diagnosticSummary: RuntimeDiagnosticSummary
    ) -> RunReadinessResult {
        let gameProfileBlockers = makeGameProfileBlockers(profiles: profiles)
        let unsupportedBlockers = makeRuntimeBlockers(
            dependencies: diagnosticSummary.dependencies,
            status: .unsupported
        )
        let missingBlockers = makeRuntimeBlockers(
            dependencies: diagnosticSummary.dependencies,
            status: .missing
        )
        let unknownBlockers = makeRuntimeBlockers(
            dependencies: diagnosticSummary.dependencies,
            status: .unknown
        )

        let blockers = gameProfileBlockers + unsupportedBlockers + missingBlockers + unknownBlockers
        let status = makeStatus(
            hasConfiguredProfile: gameProfileBlockers.isEmpty,
            unsupportedBlockers: unsupportedBlockers,
            missingBlockers: missingBlockers,
            unknownBlockers: unknownBlockers
        )

        return RunReadinessResult(
            status: status,
            title: title(for: status),
            message: message(for: status),
            blockers: blockers,
            canLaunch: false
        )
    }

    private func makeGameProfileBlockers(profiles: [GameProfile]) -> [RunReadinessBlocker] {
        guard profiles.contains(where: isConfiguredProfile) else {
            return [
                RunReadinessBlocker(
                    id: "game-profile.missing",
                    title: String(localized: "readiness.missingUserGameProfile.title"),
                    message: String(localized: "readiness.missingUserGameProfile.message"),
                    severity: .blocking,
                    source: .gameProfile,
                    suggestedAction: String(localized: "readiness.missingUserGameProfile.action"),
                    isUserActionable: true
                )
            ]
        }

        return []
    }

    private func isConfiguredProfile(_ profile: GameProfile) -> Bool {
        hasValue(profile.executablePath)
            && hasValue(profile.workingDirectory)
            && profile.executableBookmarkData?.isEmpty == false
            && profile.workingDirectoryBookmarkData?.isEmpty == false
    }

    private func hasValue(_ value: String?) -> Bool {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    private func makeRuntimeBlockers(
        dependencies: [RuntimeDependency],
        status: RuntimeDependencyStatus
    ) -> [RunReadinessBlocker] {
        dependencies
            .filter { $0.kind != .gameProfile && $0.status == status }
            .map { dependency in
                switch status {
                case .unsupported:
                    return unsupportedBlocker(for: dependency)
                case .missing:
                    return missingBlocker(for: dependency)
                case .unknown:
                    return unknownBlocker(for: dependency)
                case .ready, .notRequired:
                    return infoBlocker(for: dependency)
                }
            }
    }

    private func unsupportedBlocker(for dependency: RuntimeDependency) -> RunReadinessBlocker {
        RunReadinessBlocker(
            id: "\(dependency.kind.rawValue).unsupported",
            title: "\(String(localized: "readiness.unsupportedDependency.title")): \(dependency.displayName)",
            message: String(localized: "readiness.unsupportedDependency.message"),
            severity: .blocking,
            source: .unsupportedEnvironment,
            suggestedAction: dependency.suggestedAction,
            isUserActionable: false
        )
    }

    private func missingBlocker(for dependency: RuntimeDependency) -> RunReadinessBlocker {
        RunReadinessBlocker(
            id: "\(dependency.kind.rawValue).missing",
            title: "\(String(localized: "readiness.missingRuntimeDependency.title")): \(dependency.displayName)",
            message: String(localized: "readiness.missingRuntimeDependency.message"),
            severity: .blocking,
            source: .runtimeDependency,
            suggestedAction: dependency.suggestedAction ?? String(localized: "readiness.fixMissingBeforeLaunch"),
            isUserActionable: true
        )
    }

    private func unknownBlocker(for dependency: RuntimeDependency) -> RunReadinessBlocker {
        RunReadinessBlocker(
            id: "\(dependency.kind.rawValue).unknown",
            title: "\(String(localized: "readiness.unknownDependency.title")): \(dependency.displayName)",
            message: String(localized: "readiness.unknownDependency.message"),
            severity: .warning,
            source: .runtimeDependency,
            suggestedAction: dependency.suggestedAction,
            isUserActionable: dependency.suggestedAction != nil
        )
    }

    private func infoBlocker(for dependency: RuntimeDependency) -> RunReadinessBlocker {
        RunReadinessBlocker(
            id: "\(dependency.kind.rawValue).info",
            title: dependency.displayName,
            message: dependency.userFacingDescription,
            severity: .info,
            source: .unknown,
            suggestedAction: nil,
            isUserActionable: false
        )
    }

    private func makeStatus(
        hasConfiguredProfile: Bool,
        unsupportedBlockers: [RunReadinessBlocker],
        missingBlockers: [RunReadinessBlocker],
        unknownBlockers: [RunReadinessBlocker]
    ) -> RunReadinessStatus {
        if !unsupportedBlockers.isEmpty {
            return .unsupported
        }

        if !hasConfiguredProfile || !missingBlockers.isEmpty {
            return .blocked
        }

        if !unknownBlockers.isEmpty {
            return .unknown
        }

        return .ready
    }

    private func title(for status: RunReadinessStatus) -> String {
        switch status {
        case .ready:
            return String(localized: "readiness.ready.title")
        case .blocked:
            return String(localized: "readiness.blocked.title")
        case .unknown:
            return String(localized: "readiness.unknown.title")
        case .unsupported:
            return String(localized: "readiness.unsupported.title")
        }
    }

    private func message(for status: RunReadinessStatus) -> String {
        switch status {
        case .ready:
            return String(localized: "readiness.ready.message")
        case .blocked:
            return String(localized: "readiness.fixMissingBeforeLaunch")
        case .unknown:
            return String(localized: "readiness.unknown.message")
        case .unsupported:
            return String(localized: "readiness.unsupported.message")
        }
    }
}
