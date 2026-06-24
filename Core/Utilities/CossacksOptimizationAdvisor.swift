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
            dllConfigStatus(for: profile),
            steamStatus(for: profile),
            runtimeStatus(for: profile),
            resolutionStatus(for: profile)
        ]
    }

    // The local Cossacks port uses WineD3D; DXVK is intentionally not required.
    static func hasDLLOverrideConfigured(_ profile: GameProfile) -> Bool {
        guard let override = profile.environment["WINEDLLOVERRIDES"] else {
            return false
        }
        return override.contains(fallbackRendererOverride)
    }

    private static func dllConfigStatus(for profile: GameProfile) -> CossacksOptimizationStatusItem {
        if hasDLLOverrideConfigured(profile) {
            return CossacksOptimizationStatusItem(
                id: "dll",
                title: "WineD3D yapılandırması",
                message: "WINEDLLOVERRIDES aktif; DXVK yerine WineD3D kullanılıyor.",
                state: .ready
            )
        }

        return CossacksOptimizationStatusItem(
            id: "dll",
            title: "WineD3D yapılandırması",
            message: "WINEDLLOVERRIDES eksik; yerel port grafik ayarı kontrol edilmeli.",
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
            title: "Yerel loader",
            message: "steamclient_loader_x86.exe doğrudan yerel WineCX ile başlatılır.",
            state: .ready
        )
    }

    private static func runtimeStatus(for profile: GameProfile) -> CossacksOptimizationStatusItem {
        guard profile.runtime != .crossOver else {
            return CossacksOptimizationStatusItem(
                id: "runtime",
                title: "Çalışma zamanı",
                message: "Profil hâlâ CrossOver kullanıyor; yerel port için güncellenmeli.",
                state: .needsAttention
            )
        }

        return CossacksOptimizationStatusItem(
            id: "runtime",
            title: "Çalışma zamanı",
            message: "Profil yerel Wine/WineCX çalışma zamanı kullanıyor.",
            state: .ready
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
