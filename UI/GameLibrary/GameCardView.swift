import SwiftUI

struct GameCardView: View {
    @Bindable var appState: AppState
    let profile: GameProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(profile.displayName, systemImage: "gamecontroller.fill")
                .font(.headline)

            Text(
                String(localized: "game.profileType")
                    + ": \(GameProfileDisplayFormatter.profileKindTitle(for: profile))"
            )
                .foregroundStyle(.secondary)

            Text(
                String(localized: "game.runtime")
                    + ": \(GameProfileDisplayFormatter.runtimeTitle(for: profile.runtime))"
            )
                .foregroundStyle(.secondary)

            Text(
                String(localized: "game.performanceMode")
                    + ": \(GameProfileDisplayFormatter.performanceTitle(for: profile.performanceMode))"
            )
                .foregroundStyle(.secondary)

            Text(
                String(localized: "game.windowsVersion")
                    + ": \(GameProfileDisplayFormatter.windowsVersionTitle(for: profile.windowsVersion))"
            )
                .foregroundStyle(.secondary)

            if let setupNote = GameProfileDisplayFormatter.setupNote(for: profile) {
                Label(setupNote, systemImage: "info.circle")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }

            Divider()

            Text(String(format: String(localized: "game.playStats"), profile.launchCount, profile.totalPlayTimeMinutes))
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                Task {
                    await appState.launchGameWithSteamInitiation(profileID: profile.id)
                }
            } label: {
                if appState.launchingProfileID == profile.id {
                    Label(String(localized: "game.launching"), systemImage: "hourglass")
                        .frame(maxWidth: .infinity)
                } else {
                    Label(String(localized: "game.playButton"), systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(appState.launchingProfileID == profile.id)
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "accessibility.gameCard"), profile.displayName))
    }
}
