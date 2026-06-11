import SwiftUI

struct AddGameView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "addGame.title"),
            systemImage: "plus.circle",
            description: Text(String(localized: "addGame.description"))
        )
        .navigationTitle(String(localized: "addGame.title"))
    }
}

