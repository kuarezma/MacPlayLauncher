import Foundation

struct GameProcessMonitor {
    static let pgrepURL = URL(fileURLWithPath: "/usr/bin/pgrep")
    static let pkillURL = URL(fileURLWithPath: "/usr/bin/pkill")

    static func isProcessRunning(
        name: String,
        commandRunner: any CommandRunning = ProcessCommandRunner(allowedExecutableURLs: [pgrepURL])
    ) async -> Bool {
        let request = CommandRequest(
            executableURL: pgrepURL,
            arguments: ["-x", name],
            environment: [:],
            timeoutSeconds: 2,
            purpose: .processLookup
        )
        return (try? await commandRunner.run(request)) != nil
    }

    static func killWineProcesses(
        commandRunner: any CommandRunning = ProcessCommandRunner(allowedExecutableURLs: [pkillURL])
    ) async {
        let targets = [
            "steam.exe", "steamwebhelper.exe", "steamservice.exe",
            "steamclient_loader", "winedevice.exe", "winewrapper.exe",
            "services.exe", "plugplay.exe", "svchost.exe"
        ]
        for name in targets {
            let request = CommandRequest(
                executableURL: pkillURL,
                arguments: ["-f", name],
                environment: [:],
                timeoutSeconds: 2,
                purpose: .processKill
            )
            _ = try? await commandRunner.run(request)
        }
    }
}
