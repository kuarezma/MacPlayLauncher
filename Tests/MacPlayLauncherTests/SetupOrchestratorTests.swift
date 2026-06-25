@testable import MacPlayLauncher
import XCTest

private struct OrchestratorTestContext {
    let orchestrator: SetupOrchestrator
    let service: StubSetupService
    let installer: StubInstaller
}

@MainActor
final class SetupOrchestratorTests: XCTestCase {

    // MARK: - Helpers

    private func makeOrchestrator(
        steps: [SetupStep],
        installerResults: [SetupAutomationTarget: SetupInstallResult] = [:],
        installerError: Error? = nil
    ) -> OrchestratorTestContext {
        let service = StubSetupService(steps: steps)
        let installer = StubInstaller(results: installerResults, error: installerError)
        let orchestrator = SetupOrchestrator(
            setupService: service,
            installerService: installer,
            pollingInterval: .milliseconds(10)
        )
        return OrchestratorTestContext(orchestrator: orchestrator, service: service, installer: installer)
    }

    private func runUntilStopped(
        _ orchestrator: SetupOrchestrator,
        steps: [SetupStep],
        timeout: Duration = .seconds(2)
    ) async -> [SetupStep] {
        var lastSteps = steps
        orchestrator.startOrResume(steps: steps) { updated in
            lastSteps = updated
        }
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while orchestrator.isRunning, ContinuousClock.now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
        return lastSteps
    }

    // MARK: - Tüm adımlar tamam → orchestrator hemen durur

    func testAllStepsOkDoesNotCallInstaller() async throws {
        let steps = [
            makeStep(id: "rosetta", status: .ok(detail: "ok")),
            makeStep(id: "crossover", status: .ok(detail: "ok"))
        ]
        let ctx = makeOrchestrator(steps: steps)

        _ = await runUntilStopped(ctx.orchestrator, steps: steps)

        XCTAssertFalse(ctx.orchestrator.isRunning)
        XCTAssertTrue(ctx.installer.calledTargets.isEmpty, "Tüm adımlar tamam — installer çağrılmamalı")
    }

    // MARK: - Tek adım needsAction → installer çağrılır, sonra durur

    func testSingleNeedsActionStepCallsInstaller() async throws {
        let step = makeStep(
            id: "displayplacer",
            status: .needsAction(message: "kurulu değil"),
            canAutoFix: true,
            automationTarget: .displayplacer
        )
        let okStep = makeStep(id: "displayplacer", status: .ok(detail: "ok"))
        let ctx = makeOrchestrator(
            steps: [step],
            installerResults: [.displayplacer: .completed("kuruldu")]
        )
        // İlk detect → needsAction; installer çağrılır; ikinci detect → ok
        ctx.service.detectCallResponses = [[step], [okStep]]

        _ = await runUntilStopped(ctx.orchestrator, steps: [step])

        XCTAssertFalse(ctx.orchestrator.isRunning)
        XCTAssertEqual(ctx.installer.calledTargets, [.displayplacer])
    }

    // MARK: - waitingForUser adımı → otomatik geçiş olmaz, polling başlar

    func testWaitingForUserStepStartsPolling() async throws {
        let waitingStep = makeStep(
            id: "crossover",
            status: .waitingForUser(message: "lisans bekleniyor"),
            canAutoFix: false
        )
        let okStep = makeStep(id: "crossover", status: .ok(detail: "ok"))
        let ctx = makeOrchestrator(steps: [waitingStep])

        // Polling sırasında 2. detect çağrısında ok dönecek
        ctx.service.detectCallResponses = [
            [waitingStep],      // ilk detect (orchestration başlangıcı)
            [waitingStep],      // polling 1. tur → hâlâ bekliyor
            [okStep]            // polling 2. tur → tamamlandı
        ]

        _ = await runUntilStopped(ctx.orchestrator, steps: [waitingStep], timeout: .seconds(3))

        XCTAssertFalse(ctx.orchestrator.isRunning, "Polling tamamlanınca orchestrator durmalı")
        XCTAssertTrue(ctx.installer.calledTargets.isEmpty, "waitingForUser adımı installer çağırmamalı")
    }

    // MARK: - failed adım → orchestrator durur

    func testFailedStepStopsOrchestrator() async throws {
        let failedStep = makeStep(
            id: "bottle",
            status: .needsAction(message: "eksik"),
            canAutoFix: true,
            automationTarget: .bottle
        )
        let ctx = makeOrchestrator(
            steps: [failedStep],
            installerError: SetupInstallerError.missingCrossOver
        )
        ctx.service.nextDetectResult = [failedStep]

        _ = await runUntilStopped(ctx.orchestrator, steps: [failedStep])

        XCTAssertFalse(ctx.orchestrator.isRunning, "Hata sonrası orchestrator durmalı")
        XCTAssertEqual(ctx.installer.calledTargets, [.bottle], "Hata almadan önce install çağrılmalı")
    }

    // MARK: - Duraklatma çalışır

    func testPauseStopsOrchestration() async throws {
        let waitingStep = makeStep(
            id: "steam",
            status: .waitingForUser(message: "giriş bekleniyor"),
            canAutoFix: false
        )
        let ctx = makeOrchestrator(steps: [waitingStep])

        ctx.orchestrator.startOrResume(steps: [waitingStep]) { _ in }
        try? await Task.sleep(for: .milliseconds(30))
        ctx.orchestrator.pause()

        XCTAssertFalse(ctx.orchestrator.isRunning)
    }

    // MARK: - Steam/CrossOver kimlik bilgisi bypass yapılmıyor

    func testOrchestratorDoesNotWriteSteamCredentials() async throws {
        // Orchestrator'ın installService.install()'dan başka hiçbir dosya yazmadığını doğrula.
        // StubInstaller, Steam credential dosyası oluşturmuyor; gerçek servis de yapmamalı.
        let steamStep = makeStep(
            id: "gameInstall",
            status: .needsAction(message: "eksik"),
            canAutoFix: true,
            automationTarget: .steam
        )
        let ctx = makeOrchestrator(
            steps: [steamStep],
            installerResults: [.steam: .waitingForUser("Steam açıldı")]
        )
        ctx.service.nextDetectResult = [steamStep]

        _ = await runUntilStopped(ctx.orchestrator, steps: [steamStep])

        let credentialPath = FileManager.default.homeDirectoryForCurrentUser
            .appending(
                path: "Library/Application Support/CrossOver/Bottles/Cossacks3"
                    + "/drive_c/Program Files (x86)/Steam/config/loginusers.vdf",
                directoryHint: .notDirectory
            ).path
        // Orchestrator bu dosyayı OLUŞTURMAMALI — sadece varlığını detect edebilir
        // Test: orchestrator çalıştı ama bu dosyayı kendisi yazmadı
        // (Gerçek Steam girişi kullanıcıya ait)
        let wasWrittenByOrchestrator = FileManager.default.fileExists(atPath: credentialPath)
            && (try? String(contentsOfFile: credentialPath, encoding: .utf8))?.contains("MacPlayOrchestrator") == true
        XCTAssertFalse(wasWrittenByOrchestrator, "Orchestrator Steam kimlik bilgisi yazmamalı")
    }

    // MARK: - Log buffer doluyor

    func testLogBufferPopulatedOnCompletion() async throws {
        let step = makeStep(
            id: "rosetta",
            status: .needsAction(message: "eksik"),
            canAutoFix: true,
            automationTarget: .rosetta
        )
        let ctx = makeOrchestrator(
            steps: [step],
            installerResults: [.rosetta: .completed("Rosetta kuruldu")]
        )
        ctx.service.nextDetectResult = [makeStep(id: "rosetta", status: .ok(detail: "ok"))]

        _ = await runUntilStopped(ctx.orchestrator, steps: [step])

        XCTAssertFalse(ctx.orchestrator.lastLogText.isEmpty, "Tamamlanan adım log bırakmalı")
    }

    // MARK: - blocked adım → orchestrator önceki adımı bekler

    func testBlockedStepStopsOrchestrator() async throws {
        let blockedStep = makeStep(
            id: "gameInstall",
            status: .blocked(reason: "Önce bottle oluşturulmalı"),
            canAutoFix: false
        )
        let ctx = makeOrchestrator(steps: [blockedStep])

        _ = await runUntilStopped(ctx.orchestrator, steps: [blockedStep])

        XCTAssertFalse(ctx.orchestrator.isRunning)
        XCTAssertTrue(ctx.installer.calledTargets.isEmpty, "Blocked adımda installer çağrılmamalı")
    }

    // MARK: - Adım sırası doğru (rosetta önce, displayplacer sonra)

    func testStepsAdvanceInOrder() async throws {
        let rosetta = makeStep(
            id: "rosetta",
            status: .needsAction(message: "eksik"),
            canAutoFix: true,
            automationTarget: .rosetta
        )
        let displayplacer = makeStep(
            id: "displayplacer",
            status: .needsAction(message: "eksik"),
            canAutoFix: true,
            automationTarget: .displayplacer
        )
        let ctx = makeOrchestrator(
            steps: [rosetta, displayplacer],
            installerResults: [
                .rosetta: .completed("ok"),
                .displayplacer: .completed("ok")
            ]
        )
        // İlk detect → rosetta ok, displayplacer needsAction
        // İkinci detect → her ikisi de ok
        ctx.service.detectCallResponses = [
            [rosetta, displayplacer],
            [makeStep(id: "rosetta", status: .ok(detail: "ok")), displayplacer],
            [makeStep(id: "rosetta", status: .ok(detail: "ok")),
             makeStep(id: "displayplacer", status: .ok(detail: "ok"))]
        ]

        _ = await runUntilStopped(ctx.orchestrator, steps: [rosetta, displayplacer])

        XCTAssertFalse(ctx.orchestrator.isRunning)
        // rosetta önce, displayplacer sonra çağrılmış olmalı
        XCTAssertEqual(ctx.installer.calledTargets.first, .rosetta)
        XCTAssertTrue(ctx.installer.calledTargets.contains(.displayplacer))
    }
}

// MARK: - Stub Implementations

private final class StubSetupService: CossacksSetupServicing, @unchecked Sendable {
    private var baseSteps: [SetupStep]
    var nextDetectResult: [SetupStep]?
    var detectCallResponses: [[SetupStep]] = []
    private var detectCallCount = 0

    init(steps: [SetupStep]) {
        self.baseSteps = steps
    }

    func detectSteps() async -> [SetupStep] {
        if !detectCallResponses.isEmpty {
            let index = min(detectCallCount, detectCallResponses.count - 1)
            detectCallCount += 1
            return detectCallResponses[index]
        }
        return nextDetectResult ?? baseSteps
    }

    func applyShaderPatch() throws {}
}

private final class StubInstaller: SetupInstallerServicing, @unchecked Sendable {
    private let results: [SetupAutomationTarget: SetupInstallResult]
    private let error: Error?
    private(set) var calledTargets: [SetupAutomationTarget] = []

    init(results: [SetupAutomationTarget: SetupInstallResult], error: Error? = nil) {
        self.results = results
        self.error = error
    }

    func install(target: SetupAutomationTarget) async throws -> SetupInstallResult {
        calledTargets.append(target)
        if let error { throw error }
        return results[target] ?? .completed("ok")
    }
}

// MARK: - Factory

private func makeStep(
    id: String,
    status: SetupStepStatus,
    canAutoFix: Bool = false,
    automationTarget: SetupAutomationTarget? = nil
) -> SetupStep {
    SetupStep(
        id: id,
        title: id,
        explanation: "",
        status: status,
        canAutoFix: canAutoFix,
        automationTarget: automationTarget,
        actionLabel: nil,
        externalURL: nil,
        copyCommand: nil
    )
}
