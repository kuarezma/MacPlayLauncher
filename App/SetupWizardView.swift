import SwiftUI

struct SetupWizardView: View {
    var body: some View {
        ContentUnavailableView(
            String(localized: "setup.title"),
            systemImage: "sparkles",
            description: Text(String(localized: "setup.description"))
        )
    }
}

