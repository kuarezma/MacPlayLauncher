import Foundation

struct StaticDependencyDiagnosticService: DependencyDiagnosticServicing {
    func loadSummary(profiles: [GameProfile]) async -> RuntimeDiagnosticSummary {
        RuntimeDiagnosticSummary(
            dependencies: [
                rosettaDependency(),
                wineDependency(),
                dxvkDependency(),
                moltenVKDependency(),
                gameProfileDependency(hasConfiguredProfile: profiles.contains(where: isConfiguredProfile))
            ],
            notes: [
                String(localized: "diagnostics.note.noAutomaticInstall"),
                String(localized: "diagnostics.note.launchLater")
            ]
        )
    }

    private func rosettaDependency() -> RuntimeDependency {
        RuntimeDependency(
            displayName: "Rosetta",
            kind: .rosetta,
            status: .unknown,
            version: nil,
            installPath: nil,
            userFacingDescription: String(localized: "diagnostics.rosetta.description"),
            missingReason: String(localized: "diagnostics.rosetta.unknown"),
            suggestedAction: String(localized: "diagnostics.rosetta.suggestedAction"),
            setupGuide: RuntimeSetupGuide(
                title: String(localized: "diagnostics.rosetta.guide.title"),
                steps: [
                    String(localized: "diagnostics.rosetta.guide.step1"),
                    String(localized: "diagnostics.rosetta.guide.step2")
                ]
            )
        )
    }

    private func wineDependency() -> RuntimeDependency {
        RuntimeDependency(
            displayName: "Wine",
            kind: .wine,
            status: .missing,
            version: nil,
            installPath: nil,
            userFacingDescription: String(localized: "diagnostics.wine.description"),
            missingReason: String(localized: "diagnostics.wine.missing"),
            suggestedAction: String(localized: "diagnostics.wine.suggestedAction"),
            setupGuide: RuntimeSetupGuide(
                title: String(localized: "diagnostics.wine.guide.title"),
                steps: [
                    String(localized: "diagnostics.wine.guide.step1"),
                    String(localized: "diagnostics.wine.guide.step2")
                ]
            )
        )
    }

    private func dxvkDependency() -> RuntimeDependency {
        RuntimeDependency(
            displayName: "DXVK",
            kind: .dxvk,
            status: .missing,
            version: nil,
            installPath: nil,
            userFacingDescription: String(localized: "diagnostics.dxvk.description"),
            missingReason: String(localized: "diagnostics.dxvk.notConfigured"),
            suggestedAction: String(localized: "diagnostics.dxvk.suggestedAction"),
            setupGuide: RuntimeSetupGuide(
                title: String(localized: "diagnostics.dxvk.guide.title"),
                steps: [
                    String(localized: "diagnostics.dxvk.guide.step1"),
                    String(localized: "diagnostics.dxvk.guide.step2")
                ]
            )
        )
    }

    private func moltenVKDependency() -> RuntimeDependency {
        RuntimeDependency(
            displayName: "MoltenVK",
            kind: .moltenVK,
            status: .missing,
            version: nil,
            installPath: nil,
            userFacingDescription: String(localized: "diagnostics.moltenVK.description"),
            missingReason: String(localized: "diagnostics.moltenVK.notConfigured"),
            suggestedAction: String(localized: "diagnostics.moltenVK.suggestedAction"),
            setupGuide: RuntimeSetupGuide(
                title: String(localized: "diagnostics.moltenVK.guide.title"),
                steps: [
                    String(localized: "diagnostics.moltenVK.guide.step1"),
                    String(localized: "diagnostics.moltenVK.guide.step2")
                ]
            )
        )
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

    private func gameProfileDependency(hasConfiguredProfile: Bool) -> RuntimeDependency {
        RuntimeDependency(
            displayName: String(localized: "diagnostics.gameProfile.displayName"),
            kind: .gameProfile,
            status: hasConfiguredProfile ? .ready : .missing,
            version: nil,
            installPath: nil,
            userFacingDescription: hasConfiguredProfile
                ? String(localized: "diagnostics.gameProfile.ready")
                : String(localized: "diagnostics.gameProfile.missing"),
            missingReason: hasConfiguredProfile ? nil : String(localized: "diagnostics.gameProfile.missingReason"),
            suggestedAction: hasConfiguredProfile ? nil : String(localized: "diagnostics.gameProfile.suggestedAction"),
            setupGuide: nil
        )
    }
}
