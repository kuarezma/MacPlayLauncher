import Foundation

struct RealDependencyDiagnosticService: DependencyDiagnosticServicing {
    private let rosettaProvider: any RuntimeDiagnosticProviding
    private let wineProvider: any RuntimeDiagnosticProviding
    private let dxvkProvider: any RuntimeDiagnosticProviding
    private let moltenVKProvider: any RuntimeDiagnosticProviding

    init(
        rosettaProvider: any RuntimeDiagnosticProviding = RosettaDiagnosticProvider(),
        wineProvider: any RuntimeDiagnosticProviding = WineDiagnosticProvider(),
        dxvkProvider: any RuntimeDiagnosticProviding = PassiveRuntimeDiagnosticProvider(kind: .dxvk),
        moltenVKProvider: any RuntimeDiagnosticProviding = PassiveRuntimeDiagnosticProvider(kind: .moltenVK)
    ) {
        self.rosettaProvider = rosettaProvider
        self.wineProvider = wineProvider
        self.dxvkProvider = dxvkProvider
        self.moltenVKProvider = moltenVKProvider
    }

    func loadSummary(profiles: [GameProfile]) async -> RuntimeDiagnosticSummary {
        let rosetta = await rosettaProvider.diagnose()
        let wine = await wineProvider.diagnose()
        let dxvk = await dxvkProvider.diagnose()
        let moltenVK = await moltenVKProvider.diagnose()

        return RuntimeDiagnosticSummary(
            dependencies: [
                rosetta,
                wine,
                dxvk,
                moltenVK,
                RuntimeDependencyFactory.gameProfileDependency(for: profiles)
            ],
            notes: [
                String(localized: "diagnostics.note.noAutomaticInstall"),
                String(localized: "diagnostics.note.launchLater")
            ]
        )
    }
}
