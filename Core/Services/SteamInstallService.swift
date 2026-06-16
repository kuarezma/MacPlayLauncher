import AppKit
import Foundation

enum SteamInstallError: Error {
    case appNotFound
}

protocol SteamInstallServicing: Sendable {
    func openInstallPage(for appID: String) throws
    func openLibrary() throws
}

struct SteamInstallService: SteamInstallServicing {
    func openInstallPage(for appID: String) throws {
        guard let url = URL(string: "steam://install/\(appID)") else { return }
        try open(url)
    }

    func openLibrary() throws {
        guard let url = URL(string: "steam://open/games") else { return }
        try open(url)
    }

    private func open(_ url: URL) throws {
        let opened = NSWorkspace.shared.open(url)
        if !opened {
            throw SteamInstallError.appNotFound
        }
    }
}
