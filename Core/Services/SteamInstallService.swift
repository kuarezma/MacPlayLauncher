import AppKit
import Foundation

enum SteamInstallError: Error {
    case appNotFound
}

struct SteamInstallService {
    func open(_ url: URL) throws {
        let opened = NSWorkspace.shared.open(url)
        if !opened {
            throw SteamInstallError.appNotFound
        }
    }
}
