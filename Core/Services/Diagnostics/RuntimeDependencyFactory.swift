import Foundation

enum RuntimeDependencyFactory {
    static func staticRosettaDependency() -> RuntimeDependency {
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

    static func staticWineDependency() -> RuntimeDependency {
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

    static func crossOverManagedWineDependency() -> RuntimeDependency {
        RuntimeDependency(
            displayName: "Wine",
            kind: .wine,
            status: .notRequired,
            version: nil,
            installPath: nil,
            userFacingDescription: "Wine katmanı CrossOver tarafından yönetilir; "
                + "kullanıcıdan ayrı Wine kurulumu istenmez.",
            missingReason: nil,
            suggestedAction: nil,
            setupGuide: nil
        )
    }

    static func passiveDXVKDependency() -> RuntimeDependency {
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

    static func crossOverManagedDXVKDependency() -> RuntimeDependency {
        RuntimeDependency(
            displayName: "DXVK",
            kind: .dxvk,
            status: .notRequired,
            version: nil,
            installPath: nil,
            userFacingDescription: "DXVK ayarı CrossOver bottle içinde yönetilir; "
                + "uygulama kurulum akışını arka planda hazırlar.",
            missingReason: nil,
            suggestedAction: nil,
            setupGuide: nil
        )
    }

    static func passiveMoltenVKDependency() -> RuntimeDependency {
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

    static func crossOverManagedMoltenVKDependency() -> RuntimeDependency {
        RuntimeDependency(
            displayName: "MoltenVK",
            kind: .moltenVK,
            status: .notRequired,
            version: nil,
            installPath: nil,
            userFacingDescription: "MoltenVK, CrossOver grafik katmanı tarafından ele alınır; "
                + "kullanıcıdan ayrı kurulum beklenmez.",
            missingReason: nil,
            suggestedAction: nil,
            setupGuide: nil
        )
    }

    static func gameProfileDependency(for profiles: [GameProfile]) -> RuntimeDependency {
        let hasConfiguredProfile = profiles.contains(where: isConfiguredProfile)

        return RuntimeDependency(
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

    static func isConfiguredProfile(_ profile: GameProfile) -> Bool {
        if profile.runtime == .crossOver {
            // CrossOver manages the bottle path — only bottle name is required
            return hasValue(profile.crossOverBottleName)
        }
        return hasValue(profile.executablePath)
            && hasValue(profile.workingDirectory)
            && profile.executableBookmarkData?.isEmpty == false
            && profile.workingDirectoryBookmarkData?.isEmpty == false
    }

    private static func hasValue(_ value: String?) -> Bool {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    static func usesOnlyCrossOverRuntime(_ profiles: [GameProfile]) -> Bool {
        let configuredProfiles = profiles.filter(isConfiguredProfile)
        guard !configuredProfiles.isEmpty else {
            return false
        }

        return configuredProfiles.allSatisfy { $0.runtime == .crossOver }
    }
}
