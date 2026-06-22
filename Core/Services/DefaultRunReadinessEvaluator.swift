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
                    title: LocalizedFallback.text(
                        "readiness.missingUserGameProfile.title",
                        fallback: "Kullanıcı tarafından yapılandırılmış oyun profili bulunamadı."
                    ),
                    message: LocalizedFallback.text(
                        "readiness.missingUserGameProfile.message",
                        fallback: "Oyun klasörü ve çalıştırılabilir dosya bilgisi tamamlanmamış."
                    ),
                    severity: .blocking,
                    source: .gameProfile,
                    suggestedAction: LocalizedFallback.text(
                        "readiness.missingUserGameProfile.action",
                        fallback: "Add Game ekranından oyun klasörünü ve çalıştırılabilir dosyayı seçin."
                    ),
                    isUserActionable: true
                )
            ]
        }

        return []
    }

    private func isConfiguredProfile(_ profile: GameProfile) -> Bool {
        if profile.runtime == .crossOver {
            // CrossOver manages the bottle path — only bottle name is required
            return hasValue(profile.crossOverBottleName)
        }
        return hasValue(profile.executablePath)
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
            title: blockerTitle(
                key: "readiness.unsupportedDependency.title",
                fallback: "Desteklenmeyen bileşen",
                dependency: dependency
            ),
            message: LocalizedFallback.text(
                "readiness.unsupportedDependency.message",
                fallback: "Bu bileşen mevcut ortamda desteklenmiyor."
            ),
            severity: .blocking,
            source: .unsupportedEnvironment,
            suggestedAction: dependency.suggestedAction,
            isUserActionable: false
        )
    }

    private func missingBlocker(for dependency: RuntimeDependency) -> RunReadinessBlocker {
        RunReadinessBlocker(
            id: "\(dependency.kind.rawValue).missing",
            title: blockerTitle(
                key: "readiness.missingRuntimeDependency.title",
                fallback: "Gerekli bileşen eksik",
                dependency: dependency
            ),
            message: LocalizedFallback.text(
                "readiness.missingRuntimeDependency.message",
                fallback: "Oyunu başlatmadan önce eksik bileşen tamamlanmalı."
            ),
            severity: .blocking,
            source: .runtimeDependency,
            suggestedAction: dependency.suggestedAction ?? LocalizedFallback.text(
                "readiness.fixMissingBeforeLaunch",
                fallback: "Eksikler giderilmeden çalıştırma aktif olmayacak."
            ),
            isUserActionable: true
        )
    }

    private func unknownBlocker(for dependency: RuntimeDependency) -> RunReadinessBlocker {
        RunReadinessBlocker(
            id: "\(dependency.kind.rawValue).unknown",
            title: blockerTitle(
                key: "readiness.unknownDependency.title",
                fallback: "Bileşen durumu bilinmiyor",
                dependency: dependency
            ),
            message: LocalizedFallback.text(
                "readiness.unknownDependency.message",
                fallback: "Bu bileşenin durumu doğrulanamadı."
            ),
            severity: .warning,
            source: .runtimeDependency,
            suggestedAction: dependency.suggestedAction,
            isUserActionable: dependency.suggestedAction != nil
        )
    }

    private func blockerTitle(
        key: StaticString,
        fallback: String,
        dependency: RuntimeDependency
    ) -> String {
        "\(LocalizedFallback.text(key, fallback: fallback)): \(dependency.displayName)"
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
