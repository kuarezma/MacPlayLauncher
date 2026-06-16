import Foundation

protocol GameLaunchExecuting: Sendable {
    func start(plan: GameLaunchPlan) throws -> GameLaunchResult
}

protocol GameLaunching: Sendable {
    func launch(profile: GameProfile) throws -> GameLaunchResult
}

struct DefaultGameLauncher: GameLaunching {
    private let planner: any GameLaunchPlanning
    private let executor: any GameLaunchExecuting
    private let accessManager: any SecurityScopedAccessManaging

    init(
        planner: any GameLaunchPlanning,
        executor: any GameLaunchExecuting,
        accessManager: any SecurityScopedAccessManaging
    ) {
        self.planner = planner
        self.executor = executor
        self.accessManager = accessManager
    }

    func launch(profile: GameProfile) throws -> GameLaunchResult {
        let plan = try planner.makeLaunchPlan(for: profile)
        return try accessManager.withAccess(to: [plan.executableURL, plan.workingDirectoryURL]) {
            try executor.start(plan: plan)
        }
    }
}
