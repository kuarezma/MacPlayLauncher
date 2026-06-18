import AppKit
import Foundation

enum SteamInstallError: Error {
    case appNotFound
    case readinessTimeout
}

protocol SteamInstallServicing: Sendable {
    func openInstallPage(for appID: String) throws
    func openLibrary() throws
    func waitForReadiness(timeout: TimeInterval) async throws
}

struct SteamInstallService: SteamInstallServicing {
    private let checkInterval: TimeInterval = 0.5
    private let bundleID = "com.valvesoftware.steam"

    func openInstallPage(for appID: String) throws {
        guard let url = URL(string: "steam://install/\(appID)") else { return }
        try open(url)
    }

    func openLibrary() throws {
        guard let url = URL(string: "steam://open/games") else { return }
        try open(url)
    }

    func waitForReadiness(timeout: TimeInterval) async throws {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if isSteamRunning() && isSteamLibraryResponsive() {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s buffer
                return
            }
            try await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
        }

        throw SteamInstallError.readinessTimeout
    }

    private func open(_ url: URL) throws {
        let opened = NSWorkspace.shared.open(
            [url],
            withAppBundleIdentifier: bundleID,
            options: .async,
            additionalEventParamDescriptor: nil,
            launchIdentifiers: nil
        )
        if !opened {
            throw SteamInstallError.appNotFound
        }
    }

    private func isSteamRunning() -> Bool {
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        return runningApps.contains { $0.bundleIdentifier == bundleID }
    }

    private func isSteamLibraryResponsive() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleID && $0.activationPolicy == .regular
        }
    }
}
