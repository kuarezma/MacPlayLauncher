import SwiftUI
import Observation

struct DiagnosticsView: View {
    @Bindable var appState: AppState
    @State private var viewModel = DiagnosticsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                sourceInfoCard
                overallSection
                readinessSection
                dependencySection
                passiveNoticeSection
            }
            .padding(24)
            .frame(maxWidth: 920, alignment: .leading)
        }
        .navigationTitle(String(localized: "diagnostics.readiness.title"))
        .task {
            viewModel.setAllowsManualRealCheck(appState.canRunManualRealDiagnosticCheck)
            await reloadDiagnostics(mode: .staticOnly)
        }
    }

    private func reloadDiagnostics(mode: DiagnosticMode) async {
        let summary = await appState.loadRuntimeDiagnosticSummary(mode: mode)
        let readinessResult = appState.evaluateRunReadiness(diagnosticSummary: summary)
        viewModel.update(summary: summary, readinessResult: readinessResult)
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
                        await reloadDiagnostics(mode: .staticOnly)
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

