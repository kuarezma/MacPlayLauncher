import Foundation

enum GameProfileDisplayFormatter {
    static func runtimeTitle(for runtime: RuntimeKind) -> String {
        switch runtime {
        case .wineDXVKMoltenVK:
            return LocalizedFallback.text("runtime.wineDXVKMoltenVK", fallback: "Wine + DXVK + MoltenVK")
        case .wineD3DMetalExperimental:
            return LocalizedFallback.text("runtime.wineD3DMetalExperimental", fallback: "Wine + D3DMetal (Deneysel)")
        case .wineDXMTExperimental:
            return LocalizedFallback.text("runtime.wineDXMTExperimental", fallback: "Wine + DXMT (Deneysel)")
        case .systemWineFallback:
            return LocalizedFallback.text("runtime.systemWineFallback", fallback: "Sistem Wine")
        case .crossOver:
            return LocalizedFallback.text("runtime.crossOver", fallback: "CrossOver")
        }
    }

    static func performanceTitle(for performanceMode: PerformanceMode) -> String {
        switch performanceMode {
        case .performance:
            return LocalizedFallback.text("performance.performance", fallback: "Performans")
        case .balanced:
            return LocalizedFallback.text("performance.balanced", fallback: "Dengeli")
        case .coolBatterySafe:
            return LocalizedFallback.text("performance.coolBatterySafe", fallback: "Serin ve pil dostu")
        }
    }

    static func windowsVersionTitle(for windowsVersion: WindowsVersion) -> String {
        switch windowsVersion {
        case .win10:
            return LocalizedFallback.text("windows.win10", fallback: "Windows 10")
        case .win11:
            return LocalizedFallback.text("windows.win11", fallback: "Windows 11")
        }
    }

    static func profileKindTitle(for profile: GameProfile) -> String {
        isUserConfigured(profile)
            ? LocalizedFallback.text("game.profileType.user", fallback: "Kullanıcı profili")
            : LocalizedFallback.text("game.profileType.sample", fallback: "Örnek profil")
    }

    static func setupNote(for profile: GameProfile) -> String? {
        isUserConfigured(profile)
            ? nil
            : LocalizedFallback.text(
                "game.sampleProfile.note",
                fallback: "Bu örnek profil çalıştırılamaz; kendi oyun klasörünüzü ekleyin."
            )
    }

    static func isUserConfigured(_ profile: GameProfile) -> Bool {
        if profile.runtime == .crossOver {
            if profile.requiresWineSteam == true {
                return profile.crossOverBottleName != nil
            }
            return profile.workingDirectory != nil
                && profile.workingDirectoryBookmarkData != nil
                && profile.crossOverBottleName != nil
        }
        return profile.executablePath != nil
            && profile.workingDirectory != nil
            && profile.executableBookmarkData != nil
            && profile.workingDirectoryBookmarkData != nil
    }
}
