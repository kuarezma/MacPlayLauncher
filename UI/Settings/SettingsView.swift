import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section(String(localized: "settings.general")) {
                Text(String(localized: "settings.placeholder"))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(minWidth: 420, minHeight: 240)
        .navigationTitle(String(localized: "settings.title"))
    }
}

