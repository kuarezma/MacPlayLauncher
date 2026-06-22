import Foundation

struct CossacksOptimizationStatusItem: Equatable, Identifiable, Sendable {
    enum State: Equatable, Sendable {
        case ready
        case needsAttention
        case unavailable
    }

    let id: String
    let title: String
    let message: String
    let state: State
}

enum CossacksOptimizationAdvisor {
    static let minimapOpenGLOverride = "opengl32=n,b"
    static let fallbackRendererOverride = "d3d9,d3d11,dxgi=b"

    static func statusItems(for profile: GameProfile) -> [CossacksOptimizationStatusItem] {
        [
            minimapStatus(for: profile),
            steamStatus(for: profile),
            crossOverStatus(for: profile),
            resolutionStatus(for: profile)
        ]
    }

    static func hasMinimapFixEnabled(_ profile: GameProfile) -> Bool {
        guard let override = profile.environment["WINEDLLOVERRIDES"] else {
            return false
        }
        return override.contains(minimapOpenGLOverride)
            && override.contains(fallbackRendererOverride)
    }

    private static func minimapStatus(for profile: GameProfile) -> CossacksOptimizationStatusItem {
        if hasMinimapFixEnabled(profile) {
            return CossacksOptimizationStatusItem(
                id: "minimap",
                title: "Minimap düzeltmesi",
                message: "OpenGL proxy ve shader uyumu aktif.",
                state: .ready
            )
        }

        return CossacksOptimizationStatusItem(
            id: "minimap",
            title: "Minimap düzeltmesi",
            message: "opengl32 override eksik; minimap şeffaf kalabilir.",
            state: .needsAttention
        )
    }

    private static func steamStatus(for profile: GameProfile) -> CossacksOptimizationStatusItem {
        if profile.requiresWineSteam == true {
            return CossacksOptimizationStatusItem(
                id: "steam",
                title: "Wine Steam",
                message: "Steam önce açılıp hazır olunca oyun başlatılır.",
                state: .ready
            )
        }

        return CossacksOptimizationStatusItem(
            id: "steam",
            title: "Wine Steam",
            message: "Bu profil Steam hazırlığını otomatik istemiyor.",
            state: .needsAttention
        )
    }

    private static func crossOverStatus(for profile: GameProfile) -> CossacksOptimizationStatusItem {
        guard profile.runtime == .crossOver else {
            return CossacksOptimizationStatusItem(
                id: "crossover",
                title: "CrossOver bottle",
                message: "Profil CrossOver yerine farklı Wine çalışma zamanı kullanıyor.",
                state: .unavailable
            )
        }

        if let bottleName = profile.crossOverBottleName, !bottleName.isEmpty {
            return CossacksOptimizationStatusItem(
                id: "crossover",
                title: "CrossOver bottle",
                message: "\(bottleName) bottle hedefleniyor.",
                state: .ready
            )
        }

        return CossacksOptimizationStatusItem(
            id: "crossover",
            title: "CrossOver bottle",
            message: "Bottle adı eksik; oyun başlatılamaz.",
            state: .needsAttention
        )
    }

    private static func resolutionStatus(for profile: GameProfile) -> CossacksOptimizationStatusItem {
        let hasResolutionNote = profile.knownIssues.contains { note in
            note.contains("1280") && note.contains("800")
        }

        return CossacksOptimizationStatusItem(
            id: "resolution",
            title: "Oyun çözünürlüğü",
            message: hasResolutionNote
                ? "Başlatırken 1280×800 moda alınır, çıkışta geri döner."
                : "1280×800 notu yok; ekran akışı kontrol edilmeli.",
            state: hasResolutionNote ? .ready : .needsAttention
        )
    }
}
