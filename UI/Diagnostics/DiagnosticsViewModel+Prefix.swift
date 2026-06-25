import Foundation

@MainActor
extension DiagnosticsViewModel {
    var prefixTitle: String {
        String(localized: "diagnostics.prefix.title")
    }

    var prefixSubtitle: String {
        String(localized: "diagnostics.prefix.subtitle")
    }

    var prefixWineBootstrapNote: String {
        String(localized: "diagnostics.prefix.wineBootstrapNote")
    }

    var prefixCreateButtonTitle: String {
        String(localized: "diagnostics.prefix.createButton")
    }

    var prefixCreatingTitle: String {
        String(localized: "diagnostics.prefix.creating")
    }

    var prefixNoProfileText: String {
        String(localized: "diagnostics.prefix.noProfile")
    }

    func profileLabel(for state: PrefixDirectoryState) -> String {
        String(format: String(localized: "diagnostics.prefix.profile"), state.displayName)
    }

    func relativePathLabel(for state: PrefixDirectoryState) -> String {
        String(format: String(localized: "diagnostics.prefix.relativePath"), state.relativePath)
    }

    func absolutePathLabel(for state: PrefixDirectoryState) -> String {
        String(format: String(localized: "diagnostics.prefix.absolutePath"), state.absolutePath)
    }

    func prefixStatusText(for availability: PrefixDirectoryState.Availability) -> String {
        switch availability {
        case .missing:
            return String(localized: "diagnostics.prefix.status.missing")
        case .exists:
            return String(localized: "diagnostics.prefix.status.exists")
        }
    }

    var showsPrefixCreateButton: Bool {
        guard let prefixState, !isCreatingPrefix else {
            return false
        }

        return prefixState.availability == .missing
    }
}
