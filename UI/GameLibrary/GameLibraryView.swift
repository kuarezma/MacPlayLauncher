import SwiftUI

struct GameLibraryView: View {
    @Bindable var appState: AppState
    @State private var libraryReadiness: RunReadinessResult?

    var body: some View {
        NavigationSplitView {
            List(selection: $appState.selectedNavigationItem) {
                NavigationLink(value: AppState.NavigationItem.library) {
                    Label(String(localized: "nav.library"), systemImage: "gamecontroller")
                        .accessibilityLabel(String(localized: "accessibility.nav.library"))
                }

                NavigationLink(value: AppState.NavigationItem.addGame) {
                    Label(String(localized: "nav.addGame"), systemImage: "plus.circle")
                        .accessibilityLabel(String(localized: "accessibility.nav.addGame"))
                }

                NavigationLink(value: AppState.NavigationItem.diagnostics) {
                    Label(String(localized: "nav.diagnostics"), systemImage: "stethoscope")
                        .accessibilityLabel(String(localized: "accessibility.nav.diagnostics"))
                }

                NavigationLink(value: AppState.NavigationItem.settings) {
                    Label(String(localized: "nav.settings"), systemImage: "gearshape")
                        .accessibilityLabel(String(localized: "accessibility.nav.settings"))
                }
            }
            .navigationTitle(String(localized: "app.name"))
        } detail: {
            detailView
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedNavigationItem {
        case .library, .none:
            libraryDetail
        case .addGame:
            AddGameView(appState: appState)
        case .diagnostics:
            DiagnosticsView(appState: appState)
        case .settings:
            SettingsView()
        }
    }

    @ViewBuilder
    private var libraryDetail: some View {
        if appState.profiles.isEmpty {
            EmptyLibraryView {
                appState.showAddGame()
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let libraryReadiness {
                        LibraryReadinessStripView(result: libraryReadiness) {
                            appState.showDiagnostics()
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 16)], spacing: 16) {
                        ForEach(appState.profiles) { profile in
                            GameCardView(profile: profile)
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle(String(localized: "library.title"))
            .task(id: libraryReadinessRefreshToken) {
                libraryReadiness = await appState.libraryReadinessResult()
            }
        }
    }

    private var libraryReadinessRefreshToken: String {
        let cacheStamp = appState.cachedDiagnosticSummary?.generatedAt.timeIntervalSince1970 ?? 0
        return "\(appState.profiles.count)|\(appState.diagnosticsDisplayMode.rawValue)|\(cacheStamp)"
    }
}
