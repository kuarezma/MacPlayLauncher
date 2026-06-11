import SwiftUI

struct GameCardView: View {
    let profile: GameProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(profile.displayName, systemImage: "gamecontroller.fill")
                .font(.headline)

            Text(String(localized: "game.runtime") + ": \(profile.runtime.rawValue)")
                .foregroundStyle(.secondary)

            Text(String(localized: "game.performanceMode") + ": \(profile.performanceMode.rawValue)")
                .foregroundStyle(.secondary)

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

