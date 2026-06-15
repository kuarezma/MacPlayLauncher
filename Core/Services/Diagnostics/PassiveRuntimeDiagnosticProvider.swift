import Foundation

struct PassiveRuntimeDiagnosticProvider: RuntimeDiagnosticProviding {
    private let kind: RuntimeDependencyKind

    init(kind: RuntimeDependencyKind) {
        self.kind = kind
    }

    func diagnose() async -> RuntimeDependency {
        switch kind {
        case .dxvk:
            return RuntimeDependencyFactory.passiveDXVKDependency()
        case .moltenVK:
            return RuntimeDependencyFactory.passiveMoltenVKDependency()
        case .rosetta:
            return RuntimeDependencyFactory.staticRosettaDependency()
        case .wine:
            return RuntimeDependencyFactory.staticWineDependency()
        case .gameProfile:
            return RuntimeDependencyFactory.gameProfileDependency(for: [])
        }
    }
}
