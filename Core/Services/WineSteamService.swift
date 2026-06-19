import AppKit
import Foundation

enum WineSteamError: Error {
    case readinessTimeout
}

protocol WineSteamServicing: Sendable {
    func launch(bottleName: String) throws
    func waitForReadiness(timeout: TimeInterval) async throws
}

struct WineSteamService: WineSteamServicing {
    private static let winePath = "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/wine"
    private static let steamExeArg = "C:\\Program Files (x86)\\Steam\\steam.exe"
    private static let checkInterval: TimeInterval = 0.5

    func launch(bottleName: String) throws {
        let wineURL = URL(fileURLWithPath: Self.winePath)
        let process = Process()
        process.executableURL = wineURL
        process.arguments = ["--bottle", bottleName, Self.steamExeArg]
        var env = ProcessInfo.processInfo.environment
        env["WINEDEBUG"] = "-all"
        process.environment = env
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        // Steam runs in background; we don't wait for it to exit.
    }

    func waitForReadiness(timeout: TimeInterval) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let running = await MainActor.run {
                NSWorkspace.shared.runningApplications.contains { app in
                    let name = (app.localizedName ?? "").lowercased()
                    return name.contains("steamwebhelper") || name == "steam.exe"
                }
            }
            if running {
                // Give Steam a moment to finish initialising IPC before we launch the game.
                try await Task.sleep(nanoseconds: 2_000_000_000)
                return
            }
            try await Task.sleep(nanoseconds: UInt64(Self.checkInterval * 1_000_000_000))
        }
        throw WineSteamError.readinessTimeout
    }
}
