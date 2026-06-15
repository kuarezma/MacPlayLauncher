import SwiftUI

struct AddGameView: View {
    @Bindable var appState: AppState

    var body: some View {
        Form {
            Section {
                Button {
                    appState.selectGameFolderForAddGame()
                } label: {
                    Label(String(localized: "addGame.folder.select"), systemImage: "folder")
                }

                if let selectedFolderURL = appState.addGameForm.selectedFolderURL {
                    LabeledContent(String(localized: "addGame.folder.selected")) {
                        Text(selectedFolderURL.path)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }

                Button {
                    appState.selectExecutableForAddGame()
                } label: {
                    Label(String(localized: "addGame.exe.select"), systemImage: "doc")
                }
                .disabled(appState.addGameForm.selectedFolderURL == nil)

                if let selectedExecutableURL = appState.addGameForm.selectedExecutableURL {
                    LabeledContent(String(localized: "addGame.exe.selected")) {
                        Text(selectedExecutableURL.lastPathComponent)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
            }

            Section {
                TextField(String(localized: "addGame.name"), text: $appState.addGameForm.gameName)
                    .textFieldStyle(.roundedBorder)
            }

            Section(String(localized: "addGame.detection.status")) {
                Text(appState.addGameForm.detectionStatusMessage ?? String(localized: "addGame.detection.waiting"))
                    .foregroundStyle(.secondary)
            }

            if let errorMessage = appState.addGameForm.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            if let successMessage = appState.addGameForm.successMessage {
                Section {
                    Label(successMessage, systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                }
            }

            Section {
                HStack {
                    Button(String(localized: "addGame.cancel")) {
                        appState.cancelAddGame()
                    }

                    Spacer()

                    Button(String(localized: "addGame.save")) {
                        appState.saveAddGameProfile()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!appState.canSaveAddGameProfile)
                }
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .navigationTitle(String(localized: "addGame.title"))
    }
}
