import Foundation

enum GameProfileDisplayFormatter {
    static func runtimeTitle(for runtime: RuntimeKind) -> String {
        switch runtime {
        case .wineDXVKMoltenVK:
            return String(localized: "runtime.wineDXVKMoltenVK")
        case .wineD3DMetalExperimental:
            return String(localized: "runtime.wineD3DMetalExperimental")
        case .wineDXMTExperimental:
            return String(localized: "runtime.wineDXMTExperimental")
        case .systemWineFallback:
            return String(localized: "runtime.systemWineFallback")
        case .crossOver:
            return String(localized: "runtime.crossOver")
        }
    }

    static func performanceTitle(for performanceMode: PerformanceMode) -> String {
        switch performanceMode {
        case .performance:
            return String(localized: "performance.performance")
        case .balanced:
            return String(localized: "performance.balanced")
        case .coolBatterySafe:
            return String(localized: "performance.coolBatterySafe")
        }
    }

    static func windowsVersionTitle(for windowsVersion: WindowsVersion) -> String {
        switch windowsVersion {
        case .win10:
            return String(localized: "windows.win10")
        case .win11:
            return String(localized: "windows.win11")
        }
    }

    static func profileKindTitle(for profile: GameProfile) -> String {
        isUserConfigured(profile)
            ? String(localized: "game.profileType.user")
            : String(localized: "game.profileType.sample")
    }

    static func setupNote(for profile: GameProfile) -> String? {
        isUserConfigured(profile) ? nil : String(localized: "game.sampleProfile.note")
    }

    static func isUserConfigured(_ profile: GameProfile) -> Bool {
        if profile.runtime == .crossOver {
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
