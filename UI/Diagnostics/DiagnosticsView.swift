import SwiftUI

struct DiagnosticsView: View {
    @Bindable var appState: AppState
    @State private var viewModel = DiagnosticsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                overallSection
                dependencySection
                passiveNoticeSection
            }
            .padding(24)
            .frame(maxWidth: 920, alignment: .leading)
        }
        .navigationTitle(String(localized: "diagnostics.readiness.title"))
        .task {
            let summary = await appState.loadRuntimeDiagnosticSummary()
            viewModel.update(summary: summary)
        }
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
