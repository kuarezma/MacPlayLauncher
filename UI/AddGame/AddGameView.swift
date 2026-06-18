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

                if !appState.addGameForm.isCrossOver {
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
            }

            Section(String(localized: "addGame.steam.title")) {
                HStack {
                    TextField(String(localized: "steam_appid_placeholder"), text: $appState.steamInstallInput)
                        .textFieldStyle(.roundedBorder)

                    Button(String(localized: "steam_open_button")) {
                        appState.openSteamInstall()
                    }
                    .buttonStyle(.bordered)
                }

                Text(String(localized: "addGame.steam.help"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let steamInstallMessage = appState.steamInstallMessage {
                    Label(steamInstallMessage, systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                if let steamInstallErrorMessage = appState.steamInstallErrorMessage {
                    Label(steamInstallErrorMessage, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.red)
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
