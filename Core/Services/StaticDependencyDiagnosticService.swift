import Foundation

struct StaticDependencyDiagnosticService: DependencyDiagnosticServicing {
    func loadSummary(profiles: [GameProfile]) async -> RuntimeDiagnosticSummary {
        let runtimeDependencies: [RuntimeDependency]
        if RuntimeDependencyFactory.usesOnlyCrossOverRuntime(profiles) {
            runtimeDependencies = [
                RuntimeDependencyFactory.staticRosettaDependency(),
                RuntimeDependencyFactory.crossOverManagedWineDependency(),
                RuntimeDependencyFactory.crossOverManagedDXVKDependency(),
                RuntimeDependencyFactory.crossOverManagedMoltenVKDependency()
            ]
        } else {
            runtimeDependencies = [
                RuntimeDependencyFactory.staticRosettaDependency(),
                RuntimeDependencyFactory.staticWineDependency(),
                RuntimeDependencyFactory.passiveDXVKDependency(),
                RuntimeDependencyFactory.passiveMoltenVKDependency()
            ]
        }

        return RuntimeDiagnosticSummary(
            dependencies: runtimeDependencies + [
                RuntimeDependencyFactory.gameProfileDependency(for: profiles)
            ],
            notes: [
                String(localized: "diagnostics.note.noAutomaticInstall"),
                String(localized: "diagnostics.note.launchLater")
            ]
        )
    }
}
