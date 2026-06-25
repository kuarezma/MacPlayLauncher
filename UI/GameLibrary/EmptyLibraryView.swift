import SwiftUI

struct EmptyLibraryView: View {
    let addGameAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ContentUnavailableView(
                String(localized: "emptyLibrary.title"),
                systemImage: "gamecontroller",
                description: Text(String(localized: "emptyLibrary.description"))
            )

            Button(String(localized: "emptyLibrary.addButton"), action: addGameAction)
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(String(localized: "accessibility.addGameButton"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(String(localized: "accessibility.emptyLibrary"))
    }
}
