import Foundation

struct StaticDependencyDiagnosticService: DependencyDiagnosticServicing {
    func loadSummary(profiles: [GameProfile]) async -> RuntimeDiagnosticSummary {
        RuntimeDiagnosticSummary(
            dependencies: [
                RuntimeDependencyFactory.staticRosettaDependency(),
                RuntimeDependencyFactory.staticWineDependency(),
                RuntimeDependencyFactory.passiveDXVKDependency(),
                RuntimeDependencyFactory.passiveMoltenVKDependency(),
                RuntimeDependencyFactory.gameProfileDependency(for: profiles)
            ],
            notes: [
                String(localized: "diagnostics.note.noAutomaticInstall"),
                String(localized: "diagnostics.note.launchLater")
            ]
        )
    }
}
