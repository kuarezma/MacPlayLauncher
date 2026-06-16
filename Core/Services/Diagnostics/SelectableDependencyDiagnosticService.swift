import Foundation

struct SelectableDependencyDiagnosticService: DependencyDiagnosticServicing {
    let mode: DiagnosticMode
    let policy: DiagnosticActivationPolicy
    let staticService: any DependencyDiagnosticServicing
    let realService: any DependencyDiagnosticServicing

    init(
        mode: DiagnosticMode,
        policy: DiagnosticActivationPolicy,
        staticService: any DependencyDiagnosticServicing = StaticDependencyDiagnosticService(),
        realService: any DependencyDiagnosticServicing = RealDependencyDiagnosticService()
    ) {
        self.mode = mode
        self.policy = policy
        self.staticService = staticService
        self.realService = realService
    }

    func loadSummary(profiles: [GameProfile]) async -> RuntimeDiagnosticSummary {
        switch mode {
        case .staticOnly:
            var summary = await staticService.loadSummary(profiles: profiles)
            summary.source = .staticPreparation
            return summary
        case .realReadOnly:
            guard policy.allowsRealDiagnostics else {
                var summary = await staticService.loadSummary(profiles: profiles)
                summary.source = .staticPreparation
                return summary
            }

            var summary = await realService.loadSummary(profiles: profiles)
            summary.source = .realSystemCheck
            return summary
        }
    }
}
