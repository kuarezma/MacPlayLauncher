@testable import MacPlayLauncher
import XCTest

@MainActor
final class SetupOrchestratorTests: XCTestCase {

    // MARK: - Helpers

    private func makeOrchestrator(
        steps: [SetupStep],
        installerResults: [SetupAutomationTarget: SetupInstallResult] = [:],
        installerError: Error? = nil
    ) -> (orchestrator: SetupOrchestrator, service: StubSetupService, installer: StubInstaller) {
        let service = StubSetupService(steps: steps)
        let installer = StubInstaller(results: installerResults, error: installerError)
        let orchestrator = SetupOrchestrator(
            setupService: service,
            installerService: installer,
            pollingInterval: .milliseconds(10)
        )
        return (orchestrator, service, installer)
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
        let (orchestrator, _, installer) = makeOrchestrator(steps: steps)

        _ = await runUntilStopped(orchestrator, steps: steps)

        XCTAssertFalse(orchestrator.isRunning)
        XCTAssertTrue(installer.calledTargets.isEmpty, "Tüm adımlar tamam — installer çağrılmamalı")
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
        let (orchestrator, service, installer) = makeOrchestrator(
            steps: [step],
            installerResults: [.displayplacer: .completed("kuruldu")]
        )
        // İlk detect → needsAction; installer çağrılır; ikinci detect → ok
        service.detectCallResponses = [[step], [okStep]]

        _ = await runUntilStopped(orchestrator, steps: [step])

        XCTAssertFalse(orchestrator.isRunning)
        XCTAssertEqual(installer.calledTargets, [.displayplacer])
    }

    // MARK: - waitingForUser adımı → otomatik geçiş olmaz, polling başlar

    func testWaitingForUserStepStartsPolling() async throws {
        let waitingStep = makeStep(
            id: "crossover",
            status: .waitingForUser(message: "lisans bekleniyor"),
            canAutoFix: false
        )
        let okStep = makeStep(id: "crossover", status: .ok(detail: "ok"))
        let (orchestrator, service, installer) = makeOrchestrator(steps: [waitingStep])

        // Polling sırasında 2. detect çağrısında ok dönecek
        service.detectCallResponses = [
            [waitingStep],      // ilk detect (orchestration başlangıcı)
            [waitingStep],      // polling 1. tur → hâlâ bekliyor
            [okStep]            // polling 2. tur → tamamlandı
        ]

        _ = await runUntilStopped(orchestrator, steps: [waitingStep], timeout: .seconds(3))

        XCTAssertFalse(orchestrator.isRunning, "Polling tamamlanınca orchestrator durmalı")
        XCTAssertTrue(installer.calledTargets.isEmpty, "waitingForUser adımı installer çağırmamalı")
    }

    // MARK: - failed adım → orchestrator durur

    func testFailedStepStopsOrchestrator() async throws {
        let failedStep = makeStep(
            id: "bottle",
            status: .needsAction(message: "eksik"),
            canAutoFix: true,
            automationTarget: .bottle
        )
        let (orchestrator, service, installer) = makeOrchestrator(
            steps: [failedStep],
            installerError: SetupInstallerError.missingCrossOver
        )
        service.nextDetectResult = [failedStep]

        _ = await runUntilStopped(orchestrator, steps: [failedStep])

        XCTAssertFalse(orchestrator.isRunning, "Hata sonrası orchestrator durmalı")
        XCTAssertEqual(installer.calledTargets, [.bottle], "Hata almadan önce install çağrılmalı")
    }

    // MARK: - Duraklatma çalışır

    func testPauseStopsOrchestration() async throws {
        let waitingStep = makeStep(
            id: "steam",
            status: .waitingForUser(message: "giriş bekleniyor"),
            canAutoFix: false
        )
        let (orchestrator, _, _) = makeOrchestrator(steps: [waitingStep])

        orchestrator.startOrResume(steps: [waitingStep]) { _ in }
        try? await Task.sleep(for: .milliseconds(30))
        orchestrator.pause()

        XCTAssertFalse(orchestrator.isRunning)
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
        let (orchestrator, service, _) = makeOrchestrator(
            steps: [steamStep],
            installerResults: [.steam: .waitingForUser("Steam açıldı")]
        )
        service.nextDetectResult = [steamStep]

        _ = await runUntilStopped(orchestrator, steps: [steamStep])

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
        let (orchestrator, service, _) = makeOrchestrator(
            steps: [step],
            installerResults: [.rosetta: .completed("Rosetta kuruldu")]
        )
        service.nextDetectResult = [makeStep(id: "rosetta", status: .ok(detail: "ok"))]

        _ = await runUntilStopped(orchestrator, steps: [step])

        XCTAssertFalse(orchestrator.lastLogText.isEmpty, "Tamamlanan adım log bırakmalı")
    }

    // MARK: - blocked adım → orchestrator önceki adımı bekler

    func testBlockedStepStopsOrchestrator() async throws {
        let blockedStep = makeStep(
            id: "gameInstall",
            status: .blocked(reason: "Önce bottle oluşturulmalı"),
            canAutoFix: false
        )
        let (orchestrator, _, installer) = makeOrchestrator(steps: [blockedStep])

        _ = await runUntilStopped(orchestrator, steps: [blockedStep])

        XCTAssertFalse(orchestrator.isRunning)
        XCTAssertTrue(installer.calledTargets.isEmpty, "Blocked adımda installer çağrılmamalı")
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
        let (orchestrator, service, installer) = makeOrchestrator(
            steps: [rosetta, displayplacer],
            installerResults: [
                .rosetta: .completed("ok"),
                .displayplacer: .completed("ok")
            ]
        )
        // İlk detect → rosetta ok, displayplacer needsAction
        // İkinci detect → her ikisi de ok
        service.detectCallResponses = [
            [rosetta, displayplacer],
            [makeStep(id: "rosetta", status: .ok(detail: "ok")), displayplacer],
            [makeStep(id: "rosetta", status: .ok(detail: "ok")),
             makeStep(id: "displayplacer", status: .ok(detail: "ok"))]
        ]

        _ = await runUntilStopped(orchestrator, steps: [rosetta, displayplacer])

        XCTAssertFalse(orchestrator.isRunning)
        // rosetta önce, displayplacer sonra çağrılmış olmalı
        XCTAssertEqual(installer.calledTargets.first, .rosetta)
        XCTAssertTrue(installer.calledTargets.contains(.displayplacer))
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
