import Foundation
import Observation

// MARK: - Log

struct SetupLogEntry: Sendable {
    let date: Date
    let stepID: String
    let message: String
    let level: Level

    enum Level: Sendable { case info, warning, error }
}

actor SetupLogBuffer {
    private(set) var entries: [SetupLogEntry] = []
    private let maxEntries = 50

    func append(stepID: String, message: String, level: SetupLogEntry.Level = .info) {
        entries.append(SetupLogEntry(date: Date(), stepID: stepID, message: message, level: level))
        if entries.count > maxEntries {
            entries.removeFirst()
        }
    }

    var lastFiveText: String {
        entries.suffix(5)
            .map { "[\($0.stepID)] \($0.message)" }
            .joined(separator: "\n")
    }
}

// MARK: - Orchestrator

@MainActor
@Observable
final class SetupOrchestrator {

    private(set) var isRunning = false
    private(set) var lastLogText = ""

    let logBuffer = SetupLogBuffer()

    private let setupService: any CossacksSetupServicing
    private let installerService: any SetupInstallerServicing
    private let pollingInterval: Duration
    private var pollingTask: Task<Void, Never>?
    private var orchestrationTask: Task<Void, Never>?

    init(
        setupService: any CossacksSetupServicing,
        installerService: any SetupInstallerServicing,
        pollingInterval: Duration = .seconds(10)
    ) {
        self.setupService = setupService
        self.installerService = installerService
        self.pollingInterval = pollingInterval
    }

    // MARK: - Public API

    func startOrResume(
        steps: [SetupStep],
        onStepUpdate: @escaping @MainActor ([SetupStep]) -> Void
    ) {
        guard !isRunning else { return }
        isRunning = true
        orchestrationTask = Task { [weak self] in
            await self?.runOrchestration(currentSteps: steps, onStepUpdate: onStepUpdate)
        }
    }

    func pause() {
        orchestrationTask?.cancel()
        stopPolling()
        isRunning = false
    }

    func stop() {
        orchestrationTask?.cancel()
        stopPolling()
        isRunning = false
    }

    // MARK: - Orchestration Loop

    private enum OrchestrationControl { case keepGoing, stop }

    private func runOrchestration(
        currentSteps: [SetupStep],
        onStepUpdate: @escaping @MainActor ([SetupStep]) -> Void
    ) async {
        var steps = currentSteps

        while !Task.isCancelled {
            let fresh = await setupService.detectSteps()
            await MainActor.run { onStepUpdate(fresh) }
            steps = fresh

            guard let target = steps.first(where: { !$0.status.isOK }) else {
                await log("orchestrator", "Tüm kurulum adımları tamamlandı.", .info)
                isRunning = false
                return
            }

            let control = await process(target: target, onStepUpdate: onStepUpdate)
            if case .stop = control {
                isRunning = false
                return
            }
        }
    }

    private func process(
        target: SetupStep,
        onStepUpdate: @escaping @MainActor ([SetupStep]) -> Void
    ) async -> OrchestrationControl {
        switch target.status {
        case .ok:
            return .keepGoing

        case .blocked:
            await log(target.id, "Engellendi: önceki adım bekleniyor.", .warning)
            return .stop

        case .waitingForUser(let message):
            await log(target.id, "Kullanıcı bekleniyor: \(message)", .info)
            await pollUntilComplete(stepID: target.id, onStepUpdate: onStepUpdate)
            if Task.isCancelled { return .stop }
            return .keepGoing

        case .failed(let message):
            await log(target.id, "Hata: \(message)", .error)
            return .stop

        case .needsAction, .checking, .installing:
            return await runAutomation(target: target, onStepUpdate: onStepUpdate)
        }
    }

    private func runAutomation(
        target: SetupStep,
        onStepUpdate: @escaping @MainActor ([SetupStep]) -> Void
    ) async -> OrchestrationControl {
        guard target.canAutoFix, let automationTarget = target.automationTarget else {
            await log(target.id, "Manuel müdahale gerekiyor.", .warning)
            return .stop
        }

        await log(target.id, "Başlatılıyor: \(target.title)", .info)

        do {
            let result = try await installerService.install(target: automationTarget)
            switch result {
            case .completed(let message):
                await log(target.id, "Tamamlandı: \(message)", .info)

            case .waitingForUser(let message):
                await log(target.id, "Kullanıcı bekleniyor: \(message)", .info)
                await pollUntilComplete(stepID: target.id, onStepUpdate: onStepUpdate)
                if Task.isCancelled { return .stop }
            }
        } catch {
            await log(target.id, "Hata: \(error.localizedDescription)", .error)
            return .stop
        }

        return .keepGoing
    }

    // MARK: - Polling

    private func pollUntilComplete(
        stepID: String,
        onStepUpdate: @escaping @MainActor ([SetupStep]) -> Void
    ) async {
        while !Task.isCancelled {
            try? await Task.sleep(for: pollingInterval)
            if Task.isCancelled { return }

            let fresh = await setupService.detectSteps()
            await MainActor.run { onStepUpdate(fresh) }

            if let step = fresh.first(where: { $0.id == stepID }) {
                if step.status.isOK {
                    await log(stepID, "Otomatik algılandı: tamamlandı.", .info)
                    return
                }
                if case .failed(let msg) = step.status {
                    await log(stepID, "Polling sırasında hata: \(msg)", .error)
                    return
                }
            } else {
                return
            }
        }
    }

    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - Log Helper

    private func log(_ stepID: String, _ message: String, _ level: SetupLogEntry.Level) async {
        await logBuffer.append(stepID: stepID, message: message, level: level)
        lastLogText = await logBuffer.lastFiveText
    }
}
