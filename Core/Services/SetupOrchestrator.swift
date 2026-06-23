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

    private func runOrchestration(
        currentSteps: [SetupStep],
        onStepUpdate: @escaping @MainActor ([SetupStep]) -> Void
    ) async {
        var steps = currentSteps

        while !Task.isCancelled {
            // Her iterasyonda tüm adımları yenile
            let fresh = await setupService.detectSteps()
            await MainActor.run { onStepUpdate(fresh) }
            steps = fresh

            guard let target = steps.first(where: { !$0.status.isOK }) else {
                // Tüm adımlar tamam
                await log("orchestrator", "Tüm kurulum adımları tamamlandı.", .info)
                isRunning = false
                return
            }

            switch target.status {
            case .ok:
                continue

            case .blocked:
                // Önceki bir adım çözülmeden bu adıma geçilemez; yukarıda zaten yakalandı
                await log(target.id, "Engellendi: önceki adım bekleniyor.", .warning)
                isRunning = false
                return

            case .waitingForUser(let message):
                await log(target.id, "Kullanıcı bekleniyor: \(message)", .info)
                await pollUntilComplete(
                    stepID: target.id,
                    onStepUpdate: onStepUpdate
                )
                if Task.isCancelled { return }
                // Polling bitince döngü başa döner ve tekrar detect eder

            case .failed(let message):
                await log(target.id, "Hata: \(message)", .error)
                isRunning = false
                return

            case .needsAction, .checking, .installing:
                guard target.canAutoFix, let automationTarget = target.automationTarget else {
                    await log(target.id, "Manuel müdahale gerekiyor.", .warning)
                    isRunning = false
                    return
                }

                await log(target.id, "Başlatılıyor: \(target.title)", .info)

                do {
                    let result = try await installerService.install(target: automationTarget)
                    switch result {
                    case .completed(let message):
                        await log(target.id, "Tamamlandı: \(message)", .info)

                    case .waitingForUser(let message):
                        await log(target.id, "Kullanıcı bekleniyor: \(message)", .info)
                        await pollUntilComplete(
                            stepID: target.id,
                            onStepUpdate: onStepUpdate
                        )
                        if Task.isCancelled { return }
                    }
                } catch {
                    await log(target.id, "Hata: \(error.localizedDescription)", .error)
                    isRunning = false
                    return
                }
            }
        }
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
