import SwiftUI

struct SetupWizardView: View {
    @State var appState: AppState
    @State private var selectedStepID: String?
    @State private var copyConfirmationID: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    stepsList
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                if let errorMessage = appState.setupPatchErrorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }

                if let message = appState.setupActionMessage {
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }

                if let step = selectedStep {
                    VStack(alignment: .leading, spacing: 0) {
                        Divider()
                            .padding(.top, 12)
                        InfoPanelView(step: step)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    }
                }

                bottomBar
                    .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if appState.setupSteps.isEmpty {
                await appState.refreshSetupStatus()
                selectedStepID = appState.setupSteps.first(where: { !$0.status.isOK })?.id
            }
        }
    }

    // MARK: - Sub-views

    private var header: some View {
        HStack(spacing: 14) {
            Image(systemName: "checklist.checked")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("Kurulum Rehberi")
                    .font(.title2)
                    .fontWeight(.semibold)

                if appState.isRefreshingSetup {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Text(progressLabel)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            progressBadge
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    @ViewBuilder
    private var progressBadge: some View {
        let steps = appState.setupSteps
        if steps.isEmpty {
            EmptyView()
        } else {
            let done = steps.filter { $0.status.isOK }.count
            let total = steps.count
            HStack(spacing: 4) {
                ForEach(0..<total, id: \.self) { index in
                    Circle()
                        .fill(index < done ? Color.green : Color(nsColor: .tertiarySystemFill))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    private var progressLabel: String {
        let steps = appState.setupSteps
        if steps.isEmpty { return "Kontrol ediliyor…" }
        let done = steps.filter { $0.status.isOK }.count
        let total = steps.count
        if done == total { return "Tüm adımlar tamamlandı — oyun oynamaya hazır!" }
        return "\(done)/\(total) adım tamamlandı"
    }

    @ViewBuilder
    private var stepsList: some View {
        let steps = appState.setupSteps

        if steps.isEmpty {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .frame(height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
            }
        } else {
            ForEach(steps) { step in
                SetupStepCardView(
                    step: step,
                    isActive: selectedStepID == step.id,
                    onAction: { Task { await handleAutoFix(step: step) } },
                    onCopy: { handleCopy(step: step) }
                )
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        selectedStepID = step.id
                    }
                }
            }
        }
    }

    private var selectedStep: SetupStep? {
        guard let id = selectedStepID else { return nil }
        return appState.setupSteps.first { $0.id == id }
    }

    private var bottomBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            orchestrationLogPanel

            HStack(spacing: 10) {
                orchestrationButton

                Button {
                    Task { await appState.refreshSetupStatus() }
                } label: {
                    Label("Yenile", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(appState.isRefreshingSetup || appState.isOrchestratorRunning)

                Spacer()

                if allStepsComplete {
                    Button {
                        appState.selectedNavigationItem = .library
                    } label: {
                        Label("Oyun Kütüphanesine Git", systemImage: "gamecontroller.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private var orchestrationButton: some View {
        if allStepsComplete {
            EmptyView()
        } else {
            Button {
                appState.toggleOrchestration()
            } label: {
                if appState.isOrchestratorRunning {
                    Label("Duraklat", systemImage: "pause.fill")
                } else {
                    Label(
                        appState.orchestratorLogText.isEmpty
                            ? "Kurulumu Başlat"
                            : "Devam Et",
                        systemImage: "play.fill"
                    )
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(appState.isRefreshingSetup)
        }
    }

    @ViewBuilder
    private var orchestrationLogPanel: some View {
        let logText = appState.orchestratorLogText
        if !logText.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Text(logText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(5)

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(logText, forType: .string)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                }
                .buttonStyle(.borderless)
                .help("Logu kopyala")
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
    }

    private var allStepsComplete: Bool {
        !appState.setupSteps.isEmpty && appState.setupSteps.allSatisfy { $0.status.isOK }
    }

    // MARK: - Actions

    private func handleAutoFix(step: SetupStep) async {
        guard step.canAutoFix else { return }
        await appState.performSetupAction(for: step)
    }

    private func handleCopy(step: SetupStep) {
        guard let cmd = step.copyCommand else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cmd, forType: .string)
        copyConfirmationID = step.id
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            copyConfirmationID = nil
        }
    }
}
