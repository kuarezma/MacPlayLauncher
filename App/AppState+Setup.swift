import Foundation

@MainActor
extension AppState {
    func showSetup() {
        selectedNavigationItem = .setup
    }

    // MARK: - Orchestration

    var isOrchestratorRunning: Bool {
        setupOrchestrator?.isRunning ?? false
    }

    var orchestratorLogText: String {
        setupOrchestrator?.lastLogText ?? ""
    }

    func toggleOrchestration() {
        guard let orchestrator = setupOrchestrator else { return }
        if orchestrator.isRunning {
            orchestrator.pause()
        } else {
            orchestrator.startOrResume(steps: setupSteps) { [weak self] updated in
                guard let self else { return }
                self.setupSteps = updated
            }
        }
    }

    func stopOrchestration() {
        setupOrchestrator?.stop()
    }

    // MARK: - Status Refresh

    func refreshSetupStatus() async {
        isRefreshingSetup = true
        let detectedSteps = await environment.cossacksSetupService.detectSteps()
        setupSteps = detectedSteps.map { step in
            guard let override = setupStatusOverrides[step.id] else {
                return step
            }
            return step.replacingStatus(override)
        }
        isRefreshingSetup = false
    }

    func performSetupAction(for step: SetupStep) async {
        guard step.canAutoFix else { return }

        if step.automationTarget == .shaderPatch || step.id == "shaderPatch" {
            await applyShaderPatch()
            return
        }

        guard let target = step.automationTarget else { return }
        setupPatchErrorMessage = nil
        setupActionMessage = nil
        setSetupStatus(.installing(message: installingMessage(for: target)), for: step.id)

        do {
            let result = try await environment.setupInstallerService.install(target: target)
            switch result {
            case .completed(let message):
                setupActionMessage = message
                setSetupStatus(.ok(detail: message), for: step.id)
                await refreshSetupStatus()
            case .waitingForUser(let message):
                setupActionMessage = message
                setSetupStatus(.waitingForUser(message: message), for: step.id)
            }
        } catch {
            let message = ErrorPresenter.message(for: error)
            setupPatchErrorMessage = message
            setSetupStatus(.failed(message: message), for: step.id)
        }
    }

    func applyShaderPatch() async {
        setupPatchErrorMessage = nil
        setupActionMessage = nil
        setSetupStatus(.installing(message: "Grafik yamaları uygulanıyor…"), for: "shaderPatch")
        do {
            try environment.cossacksSetupService.applyShaderPatch()
            setupActionMessage = "Grafik yamaları uygulandı."
            setSetupStatus(.ok(detail: "Grafik yamaları uygulandı."), for: "shaderPatch")
            await refreshSetupStatus()
        } catch {
            let message = ErrorPresenter.message(for: error)
            setupPatchErrorMessage = message
            setSetupStatus(.failed(message: message), for: "shaderPatch")
        }
    }

    var setupIncompleteCount: Int {
        setupSteps.filter { !$0.status.isOK }.count
    }

    private func setSetupStatus(_ status: SetupStepStatus, for stepID: String) {
        setupStatusOverrides[stepID] = status
        setupSteps = setupSteps.map { step in
            step.id == stepID ? step.replacingStatus(status) : step
        }
    }

    private func installingMessage(for target: SetupAutomationTarget) -> String {
        switch target {
        case .rosetta:
            return "Rosetta kuruluyor…"
        case .crossOver:
            return "CrossOver trial kurulumu hazırlanıyor…"
        case .bottle:
            return "Cossacks3 bottle oluşturuluyor…"
        case .steam:
            return "Steam kurulumu hazırlanıyor…"
        case .displayplacer:
            return "displayplacer kuruluyor…"
        case .shaderPatch:
            return "Grafik yamaları uygulanıyor…"
        }
    }
}

private extension SetupStep {
    func replacingStatus(_ status: SetupStepStatus) -> SetupStep {
        SetupStep(
            id: id,
            title: title,
            explanation: explanation,
            status: status,
            canAutoFix: canAutoFix,
            automationTarget: automationTarget,
            actionLabel: actionLabel,
            externalURL: externalURL,
            copyCommand: copyCommand
        )
    }
}
