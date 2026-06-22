import SwiftUI

struct GameCardView: View {
    @Bindable var appState: AppState
    let profile: GameProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CossacksBattlePreviewView()

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(profile.displayName, systemImage: "gamecontroller.fill")
                        .font(.title3.weight(.semibold))

                    Text("Cossacks 3 için hazır başlatma profili")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Text(
                    String(
                        format: String(localized: "game.playStats"),
                        profile.launchCount,
                        profile.totalPlayTimeMinutes
                    )
                )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }

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

            CossacksOptimizationStatusView(
                items: CossacksOptimizationAdvisor.statusItems(for: profile)
            )

            Button {
                Task {
                    if profile.requiresWineSteam == true {
                        await appState.launchGameWithWineSteam(profileID: profile.id)
                    } else {
                        await appState.launchGameWithSteamInitiation(profileID: profile.id)
                    }
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
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "accessibility.gameCard"), profile.displayName))
    }
}
