import SwiftUI
import Observation

struct DiagnosticsView: View {
    @Bindable var appState: AppState
    @State private var viewModel = DiagnosticsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                nextStepCard
                sourceInfoCard
                overallSection
                readinessSection
                prefixSection
                experimentalLaunchSection
                dependencySection
                passiveNoticeSection
            }
            .padding(24)
            .frame(maxWidth: 920, alignment: .leading)
        }
        .navigationTitle(String(localized: "diagnostics.readiness.title"))
        .task {
            viewModel.setAllowsManualRealCheck(appState.canRunManualRealDiagnosticCheck)
            viewModel.setExperimentalLaunchEnabled(appState.isExperimentalLaunchEnabled)
            refreshPrefixState()
            if let cached = appState.restoreCachedDiagnosticsIfAvailable() {
                viewModel.update(
                    summary: cached.summary,
                    readinessResult: cached.readinessResult,
                    experimentalReadinessResult: appState.evaluateExperimentalRunReadiness(
                        diagnosticSummary: cached.summary
                    )
                )
            } else {
                await reloadDiagnostics(mode: .staticOnly)
            }
        }
    }

    private var nextStepCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(String(localized: "diagnostics.nextStep.heading"), systemImage: "arrow.forward.circle.fill")
                .font(.headline)

            Text(viewModel.nextStepTitle)
                .font(.title3.weight(.semibold))

            Text(viewModel.nextStepMessage)
                .foregroundStyle(.secondary)

            if viewModel.showsNextStepButton,
               let buttonTitle = viewModel.nextStepButtonTitle,
               let action = viewModel.nextAction {
                Button(buttonTitle) {
                    runNextStepAction(action)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func runNextStepAction(_ action: DiagnosticsNextAction) {
        switch action {
        case .realSystemCheck:
            Task {
                await runRealSystemCheck()
            }
        case .createPrefix:
            Task {
                await createPrefixDirectory()
            }
        case .launchExperimental:
            launchExperimentalGame()
        }
    }

    private func refreshPrefixState() {
        viewModel.setPrefixFeedbackMessage(nil)
        do {
            viewModel.updatePrefixState(try appState.loadPrefixDirectoryState())
        } catch {
            viewModel.updatePrefixState(nil)
            viewModel.setPrefixFeedbackMessage(ErrorPresenter.message(for: error))
        }
    }

    private func createPrefixDirectory() async {
        viewModel.setCreatingPrefix(true)
        defer { viewModel.setCreatingPrefix(false) }

        do {
            let state = try appState.createPrefixDirectory()
            viewModel.updatePrefixState(state)
            if state.availability == .exists {
                viewModel.setPrefixFeedbackMessage(String(localized: "diagnostics.prefix.createSuccess"))
                await reloadDiagnostics(mode: appState.diagnosticsDisplayMode)
            }
        } catch {
            viewModel.setPrefixFeedbackMessage(ErrorPresenter.message(for: error))
        }
    }

    private func reloadDiagnostics(mode: DiagnosticMode) async {
        let summary = await appState.loadRuntimeDiagnosticSummary(mode: mode)
        let readinessResult = appState.evaluateRunReadiness(diagnosticSummary: summary)
        let experimentalReadinessResult = appState.evaluateExperimentalRunReadiness(diagnosticSummary: summary)
        viewModel.update(
            summary: summary,
            readinessResult: readinessResult,
            experimentalReadinessResult: experimentalReadinessResult
        )
        appState.storeDiagnosticsSession(
            mode: mode,
            summary: summary,
            readinessResult: readinessResult
        )
    }

    private func launchExperimentalGame() {
        viewModel.setExperimentalLaunchFeedbackMessage(nil)
        viewModel.setLaunchingExperimental(true)
        defer { viewModel.setLaunchingExperimental(false) }

        do {
            let result = try appState.launchExperimentalGame()
            viewModel.setExperimentalLaunchFeedbackMessage(
                String(format: String(localized: "diagnostics.experimentalLaunch.success"), result.processIdentifier)
            )
        } catch {
            viewModel.setExperimentalLaunchFeedbackMessage(ErrorPresenter.message(for: error))
        }
    }

    private func returnToStaticPreparation() async {
        appState.resetDiagnosticsSessionToStaticPreparation()
        await reloadDiagnostics(mode: .staticOnly)
    }

    private func runRealSystemCheck() async {
        viewModel.setRunningRealCheck(true)
        defer { viewModel.setRunningRealCheck(false) }

        await reloadDiagnostics(mode: .realReadOnly)
    }

    private var sourceInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(viewModel.sourceTitle)
                    .font(.headline)
                Spacer()
                Text(viewModel.sourceBadgeText)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .foregroundStyle(.secondary)
                    .background(.quaternary, in: Capsule())
            }

            Text(viewModel.sourceSubtitle)
                .foregroundStyle(.secondary)

            if let sourceNote = viewModel.sourceNote {
                Text(sourceNote)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if let lastRealCheckText = viewModel.lastRealCheckText {
                Text(lastRealCheckText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if viewModel.isRunningRealCheck {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(viewModel.realCheckLoadingTitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.showsManualRealCheckButton {
                Button(viewModel.realCheckButtonTitle) {
                    Task {
                        await runRealSystemCheck()
                    }
                }
            } else if viewModel.showsReturnToPreparationButton {
                Button(viewModel.returnToPreparationButtonTitle) {
                    Task {
                        await returnToStaticPreparation()
                    }
                }
            }

            Text(viewModel.sourceNoInstallNote)
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(viewModel.sourceDxvkMoltenVKLaterNote)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var overallSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(viewModel.overallTitle, systemImage: "stethoscope")
                .font(.title2.weight(.semibold))
            Text(viewModel.overallDescription)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var readinessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "readiness.title"))
                .font(.headline)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.readinessTitle)
                        .font(.title3.weight(.semibold))
                    Text(viewModel.readinessMessage)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let status = viewModel.readinessResult?.status {
                    Text(viewModel.readinessBadgeText(for: status))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                        .background(viewModel.readinessBadgeColor(for: status), in: Capsule())
                }
            }

            if !viewModel.readinessBlockers.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(viewModel.readinessBlockers) { blocker in
                        readinessBlockerRow(blocker)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.launchNotImplementedText)
                Text(viewModel.noLaunchThisSprintText)
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var experimentalLaunchSection: some View {
        if viewModel.isExperimentalLaunchEnabled {
            VStack(alignment: .leading, spacing: 12) {
                Text(viewModel.experimentalLaunchTitle)
                    .font(.headline)

                Text(viewModel.experimentalLaunchSubtitle)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.experimentalReadinessTitle)
                        .font(.title3.weight(.semibold))
                    Text(viewModel.experimentalReadinessMessage)
                        .foregroundStyle(.secondary)
                }

                if !viewModel.experimentalReadinessBlockers.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.experimentalReadinessBlockers) { blocker in
                            readinessBlockerRow(blocker)
                        }
                    }
                }

                if viewModel.isLaunchingExperimental {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(viewModel.experimentalLaunchLoadingTitle)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else if viewModel.showsExperimentalLaunchButton {
                    Button(viewModel.experimentalLaunchButtonTitle) {
                        launchExperimentalGame()
                    }
                } else {
                    Text(viewModel.experimentalLaunchDisabledNote)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if let experimentalLaunchFeedbackMessage = viewModel.experimentalLaunchFeedbackMessage {
                    Text(experimentalLaunchFeedbackMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var prefixSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewModel.prefixTitle)
                .font(.headline)

            Text(viewModel.prefixSubtitle)
                .foregroundStyle(.secondary)

            if let prefixState = viewModel.prefixState {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.profileLabel(for: prefixState))
                    Text(viewModel.relativePathLabel(for: prefixState))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(viewModel.absolutePathLabel(for: prefixState))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text(viewModel.prefixStatusText(for: prefixState.availability))
                        .font(.callout.weight(.semibold))
                }

                if viewModel.isCreatingPrefix {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(viewModel.prefixCreatingTitle)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else if viewModel.showsPrefixCreateButton {
                    Button(viewModel.prefixCreateButtonTitle) {
                        Task {
                            await createPrefixDirectory()
                        }
                    }
                }
            } else {
                Text(viewModel.prefixNoProfileText)
                    .foregroundStyle(.secondary)
            }

            if let prefixFeedbackMessage = viewModel.prefixFeedbackMessage {
                Text(prefixFeedbackMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Text(viewModel.prefixWineBootstrapNote)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func readinessBlockerRow(_ blocker: RunReadinessBlocker) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(blocker.title)
                    .font(.headline)

                Spacer()

                Text(viewModel.severityText(for: blocker.severity))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .foregroundStyle(.white)
                    .background(viewModel.severityColor(for: blocker.severity), in: Capsule())
            }

            Text(blocker.message)
                .foregroundStyle(.secondary)

            if let suggestedAction = blocker.suggestedAction {
                Text(suggestedAction)
                    .font(.callout)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var dependencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "diagnostics.dependencies.title"))
                .font(.headline)

            ForEach(viewModel.dependencies) { dependency in
                dependencyRow(dependency)
            }
        }
    }

    private func dependencyRow(_ dependency: RuntimeDependency) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(dependency.displayName)
                    .font(.headline)

                Spacer()

                Text(viewModel.badgeText(for: dependency.status))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .foregroundStyle(.white)
                    .background(viewModel.badgeColor(for: dependency.status), in: Capsule())
            }

            Text(dependency.userFacingDescription)
                .foregroundStyle(.secondary)

            if let versionText = viewModel.dependencyVersionText(for: dependency) {
                Text(versionText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if let installPathText = viewModel.dependencyInstallPathText(for: dependency) {
                Text(installPathText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if let missingReason = dependency.missingReason {
                Label(missingReason, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }

            if let suggestedAction = dependency.suggestedAction {
                Text(suggestedAction)
                    .font(.callout)
            }

            if let setupGuide = dependency.setupGuide {
                DisclosureGroup(setupGuide.title) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(setupGuide.steps.enumerated()), id: \.offset) { _, step in
                            Text("- \(step)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 6)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var passiveNoticeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "diagnostics.manualSetup.title"))
                .font(.headline)
            Text(String(localized: "diagnostics.note.noAutomaticInstall"))
            Text(String(localized: "diagnostics.note.manualSetupRequired"))
            Text(String(localized: "diagnostics.note.launchLater"))
        }
        .foregroundStyle(.secondary)
        .padding(.top, 4)
    }
}
