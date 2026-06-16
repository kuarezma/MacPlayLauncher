import SwiftUI

struct GameCardView: View {
    let profile: GameProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(profile.displayName, systemImage: "gamecontroller.fill")
                .font(.headline)

            Text(String(localized: "game.profileType") + ": \(GameProfileDisplayFormatter.profileKindTitle(for: profile))")
                .foregroundStyle(.secondary)

            Text(String(localized: "game.runtime") + ": \(GameProfileDisplayFormatter.runtimeTitle(for: profile.runtime))")
                .foregroundStyle(.secondary)

            Text(String(localized: "game.performanceMode") + ": \(GameProfileDisplayFormatter.performanceTitle(for: profile.performanceMode))")
                .foregroundStyle(.secondary)

            Text(String(localized: "game.windowsVersion") + ": \(GameProfileDisplayFormatter.windowsVersionTitle(for: profile.windowsVersion))")
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
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: String(localized: "accessibility.gameCard"), profile.displayName))
    }
}
