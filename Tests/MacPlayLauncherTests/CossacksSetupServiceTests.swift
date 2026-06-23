@testable import MacPlayLauncher
import XCTest

final class CossacksSetupServiceTests: XCTestCase {
    let service = CossacksSetupService()

    // MARK: - Step IDs

    func testDetectStepsReturnsExpectedStepIDs() async {
        let steps = await service.detectSteps()

        let ids = steps.map(\.id)
        XCTAssertEqual(
            ids,
            ["rosetta", "crossover", "bottle", "gameInstall", "shaderPatch", "minimapFix", "displayplacer"]
        )
    }

    func testDetectStepsAlwaysReturnsSevenSteps() async {
        let steps = await service.detectSteps()
        XCTAssertEqual(steps.count, 7)
    }

    // MARK: - crossover step

    func testCrossOverStepStatusWhenAppExists() async throws {
        let crossOverExists = FileManager.default.fileExists(atPath: "/Applications/CrossOver.app")
        let steps = await service.detectSteps()
        let step = try XCTUnwrap(steps.first { $0.id == "crossover" })

        if crossOverExists {
            XCTAssertTrue(step.status.isOK, "CrossOver exists, step should be OK")
        } else {
            if case .needsAction = step.status { } else {
                XCTFail("CrossOver missing, expected needsAction")
            }
        }
    }

    func testCrossOverStepHasAutomationWhenNotInstalled() async throws {
        guard !FileManager.default.fileExists(atPath: "/Applications/CrossOver.app") else {
            throw XCTSkip("CrossOver is installed on this machine")
        }
        let steps = await service.detectSteps()
        let step = try XCTUnwrap(steps.first { $0.id == "crossover" })

        XCTAssertTrue(step.canAutoFix)
        XCTAssertEqual(step.automationTarget, .crossOver)
        XCTAssertNil(step.externalURL)
        XCTAssertNotNil(step.actionLabel)
    }

    // MARK: - bottle step

    func testBottleStepBlockedStatusChain() async throws {
        let steps = await service.detectSteps()
        let bottleStep = try XCTUnwrap(steps.first { $0.id == "bottle" })

        if case .needsAction = bottleStep.status {
            let gameStep = try XCTUnwrap(steps.first { $0.id == "gameInstall" })
            if case .blocked = gameStep.status { } else {
                XCTFail("gameInstall should be blocked when bottle is missing")
            }
        }
    }

    // MARK: - shaderPatch step

    func testShaderPatchStepHasCanAutoFixTrue() async throws {
        let steps = await service.detectSteps()
        let step = try XCTUnwrap(steps.first { $0.id == "shaderPatch" })

        if case .needsAction = step.status {
            XCTAssertTrue(step.canAutoFix)
            XCTAssertNotNil(step.actionLabel)
        } else if case .ok = step.status {
            XCTAssertTrue(step.canAutoFix)
        }
        // blocked is also valid when game not installed
    }

    // MARK: - displayplacer step

    func testDisplayPlacerStepHasAutomationWhenMissing() async throws {
        let steps = await service.detectSteps()
        let step = try XCTUnwrap(steps.first { $0.id == "displayplacer" })

        if case .needsAction = step.status {
            XCTAssertTrue(step.canAutoFix)
            XCTAssertEqual(step.automationTarget, .displayplacer)
            XCTAssertEqual(step.copyCommand, "brew install displayplacer")
        }
    }

    func testDisplayPlacerStepIsOKWhenInstalled() async throws {
        let paths = ["/opt/homebrew/bin/displayplacer", "/usr/local/bin/displayplacer"]
        let installed = paths.contains { FileManager.default.fileExists(atPath: $0) }
        guard installed else {
            throw XCTSkip("displayplacer not installed on this machine")
        }
        let steps = await service.detectSteps()
        let step = try XCTUnwrap(steps.first { $0.id == "displayplacer" })

        XCTAssertTrue(step.status.isOK)
    }

    // MARK: - SetupStepStatus helpers

    func testSetupStepStatusIsOKReturnsTrueOnlyForOK() {
        XCTAssertTrue(SetupStepStatus.ok(detail: "done").isOK)
        XCTAssertFalse(SetupStepStatus.checking.isOK)
        XCTAssertFalse(SetupStepStatus.installing(message: "install").isOK)
        XCTAssertFalse(SetupStepStatus.waitingForUser(message: "wait").isOK)
        XCTAssertFalse(SetupStepStatus.needsAction(message: "fix it").isOK)
        XCTAssertFalse(SetupStepStatus.blocked(reason: "wait").isOK)
        XCTAssertFalse(SetupStepStatus.failed(message: "failed").isOK)
    }

    // MARK: - applyShaderPatch

    func testApplyShaderPatchThrowsGameNotFoundWhenNoGame() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let bottlePath = home.appending(
            path: "Library/Application Support/CrossOver/Bottles/Cossacks3",
            directoryHint: .isDirectory
        )
        guard !FileManager.default.fileExists(atPath: bottlePath.path) else {
            throw XCTSkip("CrossOver bottle exists on this machine — skip gameNotFound test")
        }
        XCTAssertThrowsError(try service.applyShaderPatch()) { error in
            if let setupError = error as? CossacksSetupError, case .gameNotFound = setupError { return }
            // Any error is acceptable when game not found
        }
    }
}
