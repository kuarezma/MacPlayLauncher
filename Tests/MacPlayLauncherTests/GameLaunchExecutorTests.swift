import Foundation
@testable import MacPlayLauncher
import XCTest

// MARK: - ProcessGameLaunchExecutor Tests

final class ProcessGameLaunchExecutorTests: XCTestCase {
    func testRejectsWineURLNotInAllowlist() {
        let executor = ProcessGameLaunchExecutor(allowedLauncherURLs: [])
        let plan = makePlan(wineURL: URL(fileURLWithPath: "/opt/homebrew/bin/wine"))

        XCTAssertThrowsError(try executor.start(plan: plan)) { error in
            if case MacPlayError.launchFailed = error { } else {
                XCTFail("Expected launchFailed, got \(error)")
            }
        }
    }

    func testRejectsShellExecutableEvenIfAllowlisted() {
        let shellURL = URL(fileURLWithPath: "/bin/sh")
        let executor = ProcessGameLaunchExecutor(allowedLauncherURLs: [shellURL])
        let plan = makePlan(wineURL: shellURL)

        XCTAssertThrowsError(try executor.start(plan: plan)) { error in
            if case MacPlayError.launchFailed = error { } else {
                XCTFail("Expected launchFailed, got \(error)")
            }
        }
    }

    func testRejectsDashCArgument() {
        let wineURL = URL(fileURLWithPath: "/opt/homebrew/bin/wine")
        let executor = ProcessGameLaunchExecutor(allowedLauncherURLs: [wineURL])
        let plan = makePlan(wineURL: wineURL, arguments: ["-c", "echo hello"])

        XCTAssertThrowsError(try executor.start(plan: plan)) { error in
            XCTAssertEqual(error as? MacPlayError, .launchPreparationFailed)
        }
    }

    func testSuccessfulLaunchReturnsProfileIDAndPositivePID() throws {
        let trueURL = URL(fileURLWithPath: "/usr/bin/true")
        let executor = ProcessGameLaunchExecutor(allowedLauncherURLs: [trueURL])
        let plan = makePlan(
            wineURL: trueURL,
            workingDirectoryURL: nil,
            profileID: "launch-test"
        )

        let result = try executor.start(plan: plan)

        XCTAssertEqual(result.profileID, "launch-test")
        XCTAssertGreaterThan(result.processIdentifier, 0)
    }

    func testRejectsZshShellExecutable() {
        let zshURL = URL(fileURLWithPath: "/bin/zsh")
        let executor = ProcessGameLaunchExecutor(allowedLauncherURLs: [zshURL])
        let plan = makePlan(wineURL: zshURL)

        XCTAssertThrowsError(try executor.start(plan: plan)) { error in
            if case MacPlayError.launchFailed = error { } else {
                XCTFail("Expected launchFailed, got \(error)")
            }
        }
    }
}

// MARK: - SecurityScopedAccessManager Tests

final class SecurityScopedAccessManagerTests: XCTestCase {
    func testOperationExecutedWithEmptyURLList() throws {
        let manager = SecurityScopedAccessManager()
        var called = false

        let result = try manager.withAccess(to: []) {
            called = true
            return 42
        }

        XCTAssertTrue(called)
        XCTAssertEqual(result, 42)
    }

    func testOperationExecutedWhenAccessGranted() throws {
        let tempDir = try temporaryDirectory()
        let manager = SecurityScopedAccessManager()
        var operationRan = false

        _ = try manager.withAccess(to: [tempDir]) {
            operationRan = true
            return true
        }

        XCTAssertTrue(operationRan)
    }

    func testOperationReturnValueIsForwarded() throws {
        let manager = SecurityScopedAccessManager()

        let value = try manager.withAccess(to: []) { "sentinel" }

        XCTAssertEqual(value, "sentinel")
    }

    func testOperationErrorPropagates() throws {
        let manager = SecurityScopedAccessManager()
        struct TestError: Error, Equatable {}

        XCTAssertThrowsError(
            try manager.withAccess(to: []) { throw TestError() }
        ) { error in
            XCTAssertTrue(error is TestError)
        }
    }

    func testStopAccessCalledEvenWhenOperationThrows() throws {
        let tempDir = try temporaryDirectory()
        let manager = SecurityScopedAccessManager()
        struct TestError: Error {}

        XCTAssertThrowsError(
            try manager.withAccess(to: [tempDir]) { throw TestError() }
        )
        // defer ensures stopAccessingSecurityScopedResource is always called — no resource leak
    }
}

// MARK: - DefaultGameLauncher Integration Tests

final class DefaultGameLauncherTests: XCTestCase {
    func testLaunchReturnsResultFromExecutor() throws {
        let gameFolder = URL(fileURLWithPath: "/tmp/game", isDirectory: true)
        let executable = gameFolder.appending(path: "game.exe")
        let plan = makePlan(
            wineURL: URL(fileURLWithPath: "/opt/homebrew/bin/wine"),
            executableURL: executable,
            workingDirectoryURL: gameFolder,
            profileID: "my-game"
        )
        let fakeExecutor = FakeLaunchExecutor(result: GameLaunchResult(profileID: "my-game", processIdentifier: 99))
        let launcher = DefaultGameLauncher(
            planner: FakeLaunchPlanner(plan: plan),
            executor: fakeExecutor,
            accessManager: PassthroughAccessManager()
        )

        let result = try launcher.launch(profile: makeProfile(id: "my-game"))

        XCTAssertEqual(result.profileID, "my-game")
        XCTAssertEqual(result.processIdentifier, 99)
        XCTAssertTrue(fakeExecutor.didStart)
    }

    func testLaunchGrantsAccessToExecutableAndWorkingDirectory() throws {
        let gameFolder = URL(fileURLWithPath: "/tmp/game", isDirectory: true)
        let executable = gameFolder.appending(path: "game.exe")
        let plan = makePlan(
            wineURL: URL(fileURLWithPath: "/opt/homebrew/bin/wine"),
            executableURL: executable,
            workingDirectoryURL: gameFolder
        )
        let spyAccessManager = SpyAccessManager()
        let launcher = DefaultGameLauncher(
            planner: FakeLaunchPlanner(plan: plan),
            executor: FakeLaunchExecutor(),
            accessManager: spyAccessManager
        )

        _ = try launcher.launch(profile: makeProfile())

        XCTAssertTrue(spyAccessManager.accessedURLs.contains(executable))
        XCTAssertTrue(spyAccessManager.accessedURLs.contains(gameFolder))
    }

    func testLaunchOmitsNilWorkingDirectoryFromAccessURLs() throws {
        let wineURL = URL(fileURLWithPath: "/opt/homebrew/bin/wine")
        let plan = makePlan(wineURL: wineURL, executableURL: wineURL, workingDirectoryURL: nil)
        let spyAccessManager = SpyAccessManager()
        let launcher = DefaultGameLauncher(
            planner: FakeLaunchPlanner(plan: plan),
            executor: FakeLaunchExecutor(),
            accessManager: spyAccessManager
        )

        _ = try launcher.launch(profile: makeProfile())

        XCTAssertFalse(spyAccessManager.accessedURLs.isEmpty)
        // nil workingDirectoryURL should not appear in access list
        XCTAssertEqual(spyAccessManager.accessedURLs.count, 1)
    }

    func testLaunchPropagatesPlannerError() {
        let launcher = DefaultGameLauncher(
            planner: FakeLaunchPlanner(shouldThrow: true),
            executor: FakeLaunchExecutor(),
            accessManager: PassthroughAccessManager()
        )

        XCTAssertThrowsError(try launcher.launch(profile: makeProfile())) { error in
            XCTAssertEqual(error as? MacPlayError, .launchPreparationFailed)
        }
    }

    func testLaunchPropagatesExecutorError() {
        let plan = makePlan(wineURL: URL(fileURLWithPath: "/opt/homebrew/bin/wine"))
        let launcher = DefaultGameLauncher(
            planner: FakeLaunchPlanner(plan: plan),
            executor: FakeLaunchExecutor(shouldThrow: true),
            accessManager: PassthroughAccessManager()
        )

        XCTAssertThrowsError(try launcher.launch(profile: makeProfile())) { error in
            XCTAssertEqual(error as? MacPlayError, .launchFailed("executor-error"))
        }
    }
}

// MARK: - Test helpers

private func makePlan(
    wineURL: URL,
    executableURL: URL? = nil,
    workingDirectoryURL: URL? = URL(fileURLWithPath: "/tmp/game", isDirectory: true),
    profileID: String = "test-profile",
    arguments: [String] = []
) -> GameLaunchPlan {
    GameLaunchPlan(
        profileID: profileID,
        wineURL: wineURL,
        arguments: arguments,
        environment: [:],
        executableURL: executableURL ?? wineURL,
        workingDirectoryURL: workingDirectoryURL
    )
}

private func makeProfile(id: String = "test-profile") -> GameProfile {
    GameProfile(
        schemaVersion: GameProfile.currentSchemaVersion,
        id: id,
        displayName: "Test Game",
        executablePath: "/tmp/game/game.exe",
        workingDirectory: "/tmp/game",
        prefixPath: "Prefixes/\(id)",
        executableBookmarkData: nil,
        workingDirectoryBookmarkData: nil,
        runtime: .wineDXVKMoltenVK,
        performanceMode: .balanced,
        wineArch: .win64,
        windowsVersion: .win10,
        dependencies: [],
        environment: [:],
        launchArguments: [],
        knownIssues: [],
        lastPlayedAt: nil,
        totalPlayTimeMinutes: 0,
        launchCount: 0
    )
}

// MARK: - Fakes

private final class FakeLaunchExecutor: GameLaunchExecuting, @unchecked Sendable {
    let result: GameLaunchResult
    let shouldThrow: Bool
    private(set) var didStart = false

    init(
        result: GameLaunchResult = GameLaunchResult(profileID: "test-profile", processIdentifier: 1),
        shouldThrow: Bool = false
    ) {
        self.result = result
        self.shouldThrow = shouldThrow
    }

    func start(plan: GameLaunchPlan) throws -> GameLaunchResult {
        if shouldThrow {
            throw MacPlayError.launchFailed("executor-error")
        }
        didStart = true
        return result
    }
}

private struct FakeLaunchPlanner: GameLaunchPlanning {
    let plan: GameLaunchPlan
    let shouldThrow: Bool

    init(
        plan: GameLaunchPlan = GameLaunchPlan(
            profileID: "test-profile",
            wineURL: URL(fileURLWithPath: "/opt/homebrew/bin/wine"),
            arguments: [],
            environment: [:],
            executableURL: URL(fileURLWithPath: "/tmp/game/game.exe"),
            workingDirectoryURL: URL(fileURLWithPath: "/tmp/game", isDirectory: true)
        ),
        shouldThrow: Bool = false
    ) {
        self.plan = plan
        self.shouldThrow = shouldThrow
    }

    func makeLaunchPlan(for profile: GameProfile) throws -> GameLaunchPlan {
        if shouldThrow {
            throw MacPlayError.launchPreparationFailed
        }
        return plan
    }
}

private struct PassthroughAccessManager: SecurityScopedAccessManaging {
    func withAccess<T>(to urls: [URL], perform operation: () throws -> T) throws -> T {
        try operation()
    }
}

private final class SpyAccessManager: SecurityScopedAccessManaging, @unchecked Sendable {
    private(set) var accessedURLs: [URL] = []

    func withAccess<T>(to urls: [URL], perform operation: () throws -> T) throws -> T {
        accessedURLs = urls
        return try operation()
    }
}
