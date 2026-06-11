import SwiftUI

struct DiagnosticsView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "diagnostics.title"),
            systemImage: "stethoscope",
            description: Text(String(localized: "diagnostics.description"))
        )
        .navigationTitle(String(localized: "diagnostics.title"))
    }
}

