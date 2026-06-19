import AppKit
import Foundation

struct ProcessCommandRunner: CommandRunning {
    let allowedExecutableURLs: Set<URL>
    let outputLimitBytes: Int

    init(
        allowedExecutableURLs: Set<URL> = Self.defaultAllowedExecutableURLs,
        outputLimitBytes: Int = 64 * 1024
    ) {
        self.allowedExecutableURLs = Set(allowedExecutableURLs.map(Self.normalizedURL))
        self.outputLimitBytes = outputLimitBytes
    }

    func run(_ request: CommandRequest) async throws -> CommandResult {
        try validate(request)

        return try await Task.detached(priority: .utility) {
            try Self.runProcess(request, outputLimitBytes: outputLimitBytes)
        }.value
    }

    private func validate(_ request: CommandRequest) throws {
        let executableURL = Self.normalizedURL(request.executableURL)
        guard allowedExecutableURLs.contains(executableURL), !Self.isShellExecutable(executableURL) else {
            throw CommandError.executableNotAllowed(request.executableURL)
        }

        guard !request.arguments.contains("-c") else {
            throw CommandError.executableNotAllowed(request.executableURL)
        }

        guard request.timeoutSeconds > 0 else {
            throw CommandError.launchFailed("Command timeout must be greater than zero.")
        }
    }

    private static func runProcess(_ request: CommandRequest, outputLimitBytes: Int) throws -> CommandResult {
        let startedAt = Date()
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let outputBuffer = CommandOutputBuffer(limitBytes: outputLimitBytes)
        let completion = DispatchSemaphore(value: 0)

        process.executableURL = normalizedURL(request.executableURL)
        process.arguments = request.arguments
        if !request.environment.isEmpty {
            process.environment = request.environment
        }
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.terminationHandler = { _ in
            completion.signal()
        }

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                return
            }
            if !outputBuffer.appendStdout(data) {
                process.terminate()
            }
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                return
            }
            if !outputBuffer.appendStderr(data) {
                process.terminate()
            }
        }

        do {
            try process.run()
        } catch {
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            throw CommandError.launchFailed(error.localizedDescription)
        }

        let timeoutResult = completion.wait(timeout: .now() + request.timeoutSeconds)
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        if timeoutResult == .timedOut {
            if process.isRunning {
                process.terminate()
            }
            throw CommandError.timedOut
        }

        if outputBuffer.isOverLimit {
            throw CommandError.outputTooLarge
        }

        let exitCode = process.terminationStatus
        if exitCode != 0 {
            throw CommandError.nonZeroExit(exitCode)
        }

        return CommandResult(
            exitCode: exitCode,
            stdout: outputBuffer.stdoutString,
            stderr: outputBuffer.stderrString,
            duration: Date().timeIntervalSince(startedAt)
        )
    }

    fileprivate static func normalizedURL(_ url: URL) -> URL {
        url.standardizedFileURL.resolvingSymlinksInPath()
    }

    fileprivate static func isShellExecutable(_ url: URL) -> Bool {
        let path = normalizedURL(url).path
        let name = url.lastPathComponent
        return path == "/bin/sh"
            || path == "/bin/zsh"
            || path == "/bin/bash"
            || name == "sh"
            || name == "zsh"
            || name == "bash"
    }

    private static var defaultAllowedExecutableURLs: Set<URL> {
        defaultAllowedWineURLs
            .union(defaultAllowedCrossOverURLs)
            .union([
                URL(fileURLWithPath: "/usr/bin/true"),
                URL(fileURLWithPath: "/usr/bin/arch")
            ])
    }

    fileprivate static var defaultAllowedWineURLs: Set<URL> {
        [
            URL(fileURLWithPath: "/opt/homebrew/bin/wine"),
            URL(fileURLWithPath: "/usr/local/bin/wine")
        ]
    }

    fileprivate static var defaultAllowedCrossOverURLs: Set<URL> {
        Set(CrossOverExecutableResolver.defaultAllowedURLs)
    }
}

struct ProcessGameLaunchExecutor: GameLaunchExecuting {
    private let allowedLauncherURLs: Set<URL>

    init(allowedLauncherURLs: Set<URL> = ProcessCommandRunner.defaultAllowedWineURLs
            .union(ProcessCommandRunner.defaultAllowedCrossOverURLs)) {
        self.allowedLauncherURLs = Set(allowedLauncherURLs.map { ProcessCommandRunner.normalizedURL($0) })
    }

    func start(plan: GameLaunchPlan) throws -> GameLaunchResult {
        let wineURL = ProcessCommandRunner.normalizedURL(plan.wineURL)
        guard allowedLauncherURLs.contains(wineURL), !ProcessCommandRunner.isShellExecutable(wineURL) else {
            throw MacPlayError.launchFailed(String(localized: "error.launchWineNotAllowed"))
        }

        guard !plan.arguments.contains("-c") else {
            throw MacPlayError.launchPreparationFailed
        }

        let process = Process()
        process.executableURL = wineURL
        process.arguments = plan.arguments
        process.currentDirectoryURL = plan.workingDirectoryURL
        process.environment = plan.environment

        do {
            try process.run()
        } catch {
            throw MacPlayError.launchFailed(error.localizedDescription)
        }

        return GameLaunchResult(
            profileID: plan.profileID,
            processIdentifier: process.processIdentifier
        )
    }
}

private final class CommandOutputBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private let limitBytes: Int
    private var stdoutData = Data()
    private var stderrData = Data()
    private(set) var isOverLimit = false

    init(limitBytes: Int) {
        self.limitBytes = limitBytes
    }

    var stdoutString: String {
        lock.withLock {
            String(data: stdoutData, encoding: .utf8) ?? ""
        }
    }

    var stderrString: String {
        lock.withLock {
            String(data: stderrData, encoding: .utf8) ?? ""
        }
    }

    func appendStdout(_ data: Data) -> Bool {
        append(data, to: \.stdoutData)
    }

    func appendStderr(_ data: Data) -> Bool {
        append(data, to: \.stderrData)
    }

    private func append(_ data: Data, to keyPath: ReferenceWritableKeyPath<CommandOutputBuffer, Data>) -> Bool {
        lock.withLock {
            self[keyPath: keyPath].append(data)
            if stdoutData.count + stderrData.count > limitBytes {
                isOverLimit = true
                return false
            }
            return true
        }
    }
}

// MARK: - Display Resolution Service

protocol DisplayResolutionServicing: Sendable {
    func setGameResolution()
    func restoreResolution()
}

final class DisplayResolutionService: DisplayResolutionServicing, @unchecked Sendable {
    private static let displayplacerPath = "/opt/homebrew/bin/displayplacer"
    private static let gameWidth = 1280
    private static let gameHeight = 800

    private var savedConfig: String?

    func setGameResolution() {
        guard let (id, currentMode) = mainDisplayConfig() else { return }
        savedConfig = "id:\(id) \(currentMode)"
        let gameMode = replaceResolution(in: currentMode, width: Self.gameWidth, height: Self.gameHeight)
        runDisplayplacer("id:\(id) \(gameMode)")
    }

    func restoreResolution() {
        guard let config = savedConfig else { return }
        runDisplayplacer(config)
        savedConfig = nil
    }

    private func replaceResolution(in mode: String, width: Int, height: Int) -> String {
        let pattern = #"res:\d+x\d+"#
        guard let range = mode.range(of: pattern, options: .regularExpression) else { return mode }
        return mode.replacingCharacters(in: range, with: "res:\(width)x\(height)")
    }

    private func mainDisplayConfig() -> (id: String, mode: String)? {
        guard let output = runAndCapture(["list"]) else { return nil }
        var id: String?
        var mode: String?
        for line in output.components(separatedBy: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("Persistent screen id:"), let v = t.components(separatedBy: ": ").last {
                id = v.trimmingCharacters(in: .whitespaces)
            }
            if t.contains("<-- current mode") {
                if let colon = t.firstIndex(of: ":"),
                   let start = t.index(colon, offsetBy: 2, limitedBy: t.endIndex) {
                    mode = String(t[start...])
                        .replacingOccurrences(of: "<-- current mode", with: "")
                        .trimmingCharacters(in: .whitespaces)
                }
            }
        }
        guard let displayId = id, let currentMode = mode else { return nil }
        return (displayId, currentMode)
    }

    private func runAndCapture(_ args: [String]) -> String? {
        guard FileManager.default.fileExists(atPath: Self.displayplacerPath) else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.displayplacerPath)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
    }

    private func runDisplayplacer(_ config: String) {
        guard FileManager.default.fileExists(atPath: Self.displayplacerPath) else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.displayplacerPath)
        process.arguments = [config]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }
}

// MARK: - Wine Steam Service

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
                try await Task.sleep(nanoseconds: 2_000_000_000)
                return
            }
            try await Task.sleep(nanoseconds: UInt64(Self.checkInterval * 1_000_000_000))
        }
        throw WineSteamError.readinessTimeout
    }
}

// MARK: - Game Process Monitor

struct GameProcessMonitor {
    static func isProcessRunning(name: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", name]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
