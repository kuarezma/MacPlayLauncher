import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        Form {
            Section(String(localized: "settings.general")) {
                Text(String(localized: "settings.about.personalUse"))
                    .foregroundStyle(.secondary)
            }

            Section(String(localized: "settings.diagnostics.title")) {
                Text(String(localized: "settings.diagnostics.staticDefault"))
                    .foregroundStyle(.secondary)

                Text(String(localized: "settings.diagnostics.manualRealCheck"))
                    .foregroundStyle(.secondary)

                LabeledContent(
                    String(localized: "settings.diagnostics.currentSource"),
                    value: appState.diagnosticsSessionSourceLabel
                )

                LabeledContent(
                    String(localized: "settings.experimentalLaunch.status"),
                    value: appState.experimentalLaunchStatusLabel
                )

                LabeledContent(String(localized: "settings.appDataFolder")) {
                    Text(appState.appDataFolderPath)
                        .textSelection(.enabled)
                }

                Button(String(localized: "library.readiness.openDiagnostics")) {
                    appState.showDiagnostics()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 420, minHeight: 280)
        .navigationTitle(String(localized: "settings.title"))
    }
}
