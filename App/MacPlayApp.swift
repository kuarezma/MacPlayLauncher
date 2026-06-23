import SwiftUI

@main
struct MacPlayApp: App {
    @State private var appState = AppState(environment: .live)

    var body: some Scene {
        WindowGroup {
            GameLibraryView(appState: appState)
                .task {
                    await appState.loadInitialProfiles()
                    await appState.startAutomaticSetupIfNeeded()
                }
        }
        .commands {
            CommandMenu(String(localized: "menu.navigate")) {
                Button(String(localized: "menu.addGame")) {
                    appState.showAddGame()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button(String(localized: "menu.diagnostics")) {
                    appState.showDiagnostics()
                }
                .keyboardShortcut("d", modifiers: .command)
            }

            CommandGroup(replacing: .appSettings) {
                Button(String(localized: "menu.settings")) {
                    appState.showSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        Settings {
            SettingsView(appState: appState)
        }
    }
}
