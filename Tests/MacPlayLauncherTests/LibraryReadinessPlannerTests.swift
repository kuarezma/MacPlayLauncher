import XCTest
@testable import MacPlayLauncher

final class LibraryReadinessPlannerTests: XCTestCase {
    func testPlannerBuildsStepsInExpectedOrder() {
        let plan = LibraryReadinessPlanner.make(
            profiles: [GameProfile.sampleCossacks3],
            diagnosticSummary: makeSummary(source: .staticPreparation, wineStatus: .missing),
            readinessResult: makeReadiness(canLaunch: false),
            experimentalReadinessResult: makeReadiness(canLaunch: false),
            prefixState: nil
        )

        XCTAssertEqual(
            plan.steps.map(\.id),
            ["game-folder", "real-system-check", "wine", "prefix", "experimental-launch"]
        )
        XCTAssertEqual(plan.steps[0].actionTitle, "Oyun ekle")
        XCTAssertEqual(plan.steps[1].actionTitle, "Gerçek sistemi kontrol et")
    }

    func testPlannerUsesRealCheckSummaryForWineStatus() throws {
        let plan = LibraryReadinessPlanner.make(
            profiles: [makeUserProfile()],
            diagnosticSummary: makeSummary(source: .realSystemCheck, wineStatus: .ready),
            readinessResult: makeReadiness(canLaunch: false),
            experimentalReadinessResult: makeReadiness(canLaunch: false),
            prefixState: makePrefixState(.missing)
        )

        let realCheckStep = try XCTUnwrap(plan.steps.first { $0.id == "real-system-check" })
        let wineStep = try XCTUnwrap(plan.steps.first { $0.id == "wine" })

        XCTAssertEqual(realCheckStep.status, .complete)
        XCTAssertEqual(wineStep.status, .complete)
        XCTAssertNil(wineStep.actionTitle)
    }

    func testPlannerShowsPrefixCreateActionWhenPrefixIsMissing() throws {
        let plan = LibraryReadinessPlanner.make(
            profiles: [makeUserProfile()],
            diagnosticSummary: makeSummary(source: .realSystemCheck, wineStatus: .ready),
            readinessResult: makeReadiness(canLaunch: false),
            experimentalReadinessResult: makeReadiness(canLaunch: false),
            prefixState: makePrefixState(.missing)
        )

        let prefixStep = try XCTUnwrap(plan.steps.first { $0.id == "prefix" })

        XCTAssertEqual(prefixStep.status, .needsAction)
        XCTAssertEqual(prefixStep.actionTitle, "Prefix oluştur")
        XCTAssertEqual(prefixStep.action, .openDiagnostics)
    }

    func testPlannerMarksPrefixDoneWhenDirectoryExists() throws {
        let plan = LibraryReadinessPlanner.make(
            profiles: [makeUserProfile()],
            diagnosticSummary: makeSummary(source: .realSystemCheck, wineStatus: .ready),
            readinessResult: makeReadiness(canLaunch: false),
            experimentalReadinessResult: makeReadiness(canLaunch: true),
            prefixState: makePrefixState(.exists)
        )

        let prefixStep = try XCTUnwrap(plan.steps.first { $0.id == "prefix" })
        let experimentalStep = try XCTUnwrap(plan.steps.first { $0.id == "experimental-launch" })

        XCTAssertEqual(prefixStep.status, .complete)
        XCTAssertNil(prefixStep.actionTitle)
        XCTAssertEqual(experimentalStep.status, .complete)
        XCTAssertTrue(plan.isReady)
    }

    private func makeUserProfile() -> GameProfile {
        GameProfile(
            schemaVersion: GameProfile.currentSchemaVersion,
            id: "user-game",
            displayName: "User Game",
            executablePath: "/Games/User/Game.exe",
            workingDirectory: "/Games/User",
            prefixPath: "Prefixes/user-game",
            executableBookmarkData: Data([1]),
            workingDirectoryBookmarkData: Data([2]),
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

    private func makeSummary(
        source: DiagnosticsSource,
        wineStatus: RuntimeDependencyStatus
    ) -> RuntimeDiagnosticSummary {
        RuntimeDiagnosticSummary(
            dependencies: [
                RuntimeDependency(
                    displayName: "Wine",
                    kind: .wine,
                    status: wineStatus,
                    version: nil,
                    installPath: nil,
                    userFacingDescription: "test",
                    missingReason: nil,
                    suggestedAction: nil,
                    setupGuide: nil
                )
            ],
            source: source
        )
    }

    private func makeReadiness(canLaunch: Bool) -> RunReadinessResult {
        RunReadinessResult(
            status: canLaunch ? .ready : .blocked,
            title: canLaunch ? "ready" : "blocked",
            message: canLaunch ? "ready" : "blocked",
            blockers: [],
            canLaunch: canLaunch
        )
    }

    private func makePrefixState(_ availability: PrefixDirectoryState.Availability) -> PrefixDirectoryState {
        PrefixDirectoryState(
            profileID: "user-game",
            displayName: "User Game",
            relativePath: "Prefixes/user-game",
            absolutePath: "/tmp/MacPlayLauncher/Prefixes/user-game",
            availability: availability
        )
    }
}
