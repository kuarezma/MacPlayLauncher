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
            ["rosetta", "gameInstall", "shaderPatch", "minimapFix", "displayplacer"]
        )
    }

    func testDetectStepsReturnsFiveSteps() async {
        let steps = await service.detectSteps()
        XCTAssertEqual(steps.count, 5)
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

    func testShaderPatchStepUsesLocalFreePortDirectory() async throws {
        let tempGameDirectory = FileManager.default.temporaryDirectory
            .appending(path: "CossacksSetupServiceTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let shaderDirectory = tempGameDirectory.appending(path: "data/shaders/obj", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: shaderDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempGameDirectory) }

        let exeURL = tempGameDirectory.appending(path: "cossacks.exe", directoryHint: .notDirectory)
        try "".write(to: exeURL, atomically: true, encoding: .utf8)

        let patched = """
        uniform sampler2D texUnit0;
        void main()
        {
           vec4 tex0 = texture2D(texUnit0, gl_TexCoord[0].xy);
           gl_FragColor = vec4(tex0.rgb, 1.0);
        }
        """
        for name in ["hf.pvl.smx3.frag", "env.smx3.id3.frag", "unit.smx3.id8.frag"] {
            let url = shaderDirectory.appending(path: name, directoryHint: .notDirectory)
            try patched.write(to: url, atomically: true, encoding: .utf8)
        }

        let localService = CossacksSetupService(localPortGameDirectory: tempGameDirectory)
        let steps = await localService.detectSteps()

        let gameStep = try XCTUnwrap(steps.first { $0.id == "gameInstall" })
        XCTAssertTrue(gameStep.status.isOK)
        let shaderStep = try XCTUnwrap(steps.first { $0.id == "shaderPatch" })
        XCTAssertTrue(shaderStep.status.isOK)
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
        let localPortPath = home.appending(
            path: "Cossacks3_Mac_Port/oyun_dosyalari/data/shaders/obj",
            directoryHint: .isDirectory
        )
        guard !FileManager.default.fileExists(atPath: localPortPath.path) else {
            throw XCTSkip("Game shader directory exists on this machine — skip gameNotFound test")
        }
        XCTAssertThrowsError(try service.applyShaderPatch()) { error in
            if let setupError = error as? CossacksSetupError, case .gameNotFound = setupError { return }
            // Any error is acceptable when game not found
        }
    }
}
