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
        let context = makeProcessContext(request, outputLimitBytes: outputLimitBytes)
        defer { context.detachReaders() }

        do {
            try context.process.run()
        } catch {
            throw CommandError.launchFailed(error.localizedDescription)
        }

        try waitForProcess(context.process, completion: context.completion, timeout: request.timeoutSeconds)
        try validateOutput(context.outputBuffer)
        let exitCode = try validatedExitCode(context.process)

        return CommandResult(
            exitCode: exitCode,
            stdout: context.outputBuffer.stdoutString,
            stderr: context.outputBuffer.stderrString,
            duration: Date().timeIntervalSince(startedAt)
        )
    }

    private static func makeProcessContext(_ request: CommandRequest, outputLimitBytes: Int) -> CommandProcessContext {
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

        attachReaders(
            process: process,
            stdoutPipe: stdoutPipe,
            stderrPipe: stderrPipe,
            outputBuffer: outputBuffer
        )
        return CommandProcessContext(
            process: process,
            stdoutPipe: stdoutPipe,
            stderrPipe: stderrPipe,
            outputBuffer: outputBuffer,
            completion: completion
        )
    }

    private static func attachReaders(
        process: Process,
        stdoutPipe: Pipe,
        stderrPipe: Pipe,
        outputBuffer: CommandOutputBuffer
    ) {
        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            appendAvailableData(from: handle, to: outputBuffer.appendStdout, process: process)
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            appendAvailableData(from: handle, to: outputBuffer.appendStderr, process: process)
        }
    }

    private static func appendAvailableData(
        from handle: FileHandle,
        to append: (Data) -> Bool,
        process: Process
    ) {
        let data = handle.availableData
        guard !data.isEmpty else {
            return
        }
        if !append(data) {
            process.terminate()
        }
    }

    private static func waitForProcess(
        _ process: Process,
        completion: DispatchSemaphore,
        timeout: TimeInterval
    ) throws {
        let timeoutResult = completion.wait(timeout: .now() + timeout)
        if timeoutResult == .timedOut {
            if process.isRunning {
                process.terminate()
            }
            throw CommandError.timedOut
        }
    }

    private static func validateOutput(_ outputBuffer: CommandOutputBuffer) throws {
        if outputBuffer.isOverLimit {
            throw CommandError.outputTooLarge
        }
    }

    private static func validatedExitCode(_ process: Process) throws -> Int32 {
        let exitCode = process.terminationStatus
        if exitCode != 0 {
            throw CommandError.nonZeroExit(exitCode)
        }
        return exitCode
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
                URL(fileURLWithPath: "/usr/bin/arch"),
                URL(fileURLWithPath: "/usr/bin/open"),
                URL(fileURLWithPath: "/usr/sbin/softwareupdate"),
                URL(fileURLWithPath: "/opt/homebrew/bin/brew"),
                URL(fileURLWithPath: "/usr/local/bin/brew"),
                URL(fileURLWithPath: "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/cxbottle")
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

private struct CommandProcessContext {
    let process: Process
    let stdoutPipe: Pipe
    let stderrPipe: Pipe
    let outputBuffer: CommandOutputBuffer
    let completion: DispatchSemaphore

    func detachReaders() {
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil
    }
}

// MARK: - Display Resolution Service

protocol DisplayResolutionServicing: Sendable {
    func setGameResolution() async
    func restoreResolution() async
}

actor DisplayResolutionService: DisplayResolutionServicing {
    private static let displayplacerPath = "/opt/homebrew/bin/displayplacer"
    private static let gameWidth = 1280
    private static let gameHeight = 800

    private let commandRunner: any CommandRunning
    private let displayplacerURL: URL
    private let fileExists: @Sendable (String) -> Bool
    private var savedConfig: String?

    init(
        commandRunner: (any CommandRunning)? = nil,
        displayplacerURL: URL = URL(fileURLWithPath: displayplacerPath),
        fileExists: @escaping @Sendable (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
    ) {
        self.displayplacerURL = displayplacerURL
        self.commandRunner = commandRunner ?? ProcessCommandRunner(allowedExecutableURLs: [displayplacerURL])
        self.fileExists = fileExists
    }

    func setGameResolution() async {
        guard let (id, currentMode) = await mainDisplayConfig() else { return }
        savedConfig = "id:\(id) \(currentMode)"
        let gameMode = replaceResolution(in: currentMode, width: Self.gameWidth, height: Self.gameHeight)
        await runDisplayplacer("id:\(id) \(gameMode)")
    }

    func restoreResolution() async {
        guard let config = savedConfig else { return }
        await runDisplayplacer(config)
        savedConfig = nil
    }

    private func replaceResolution(in mode: String, width: Int, height: Int) -> String {
        let pattern = #"res:\d+x\d+"#
        guard let range = mode.range(of: pattern, options: .regularExpression) else { return mode }
        return mode.replacingCharacters(in: range, with: "res:\(width)x\(height)")
    }

    private func mainDisplayConfig() async -> (id: String, mode: String)? {
        guard let output = await runAndCapture(["list"]) else { return nil }
        var id: String?
        var mode: String?
        for line in output.components(separatedBy: "\n") {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("Persistent screen id:"),
               let value = trimmedLine.components(separatedBy: ": ").last {
                id = value.trimmingCharacters(in: .whitespaces)
            }
            if trimmedLine.contains("<-- current mode") {
                if let colon = trimmedLine.firstIndex(of: ":"),
                   let start = trimmedLine.index(colon, offsetBy: 2, limitedBy: trimmedLine.endIndex) {
                    mode = String(trimmedLine[start...])
                        .replacingOccurrences(of: "<-- current mode", with: "")
                        .trimmingCharacters(in: .whitespaces)
                }
            }
        }
        guard let displayId = id, let currentMode = mode else { return nil }
        return (displayId, currentMode)
    }

    private func runAndCapture(_ args: [String]) async -> String? {
        guard fileExists(displayplacerURL.path) else { return nil }
        let request = CommandRequest(
            executableURL: displayplacerURL,
            arguments: args,
            environment: [:],
            timeoutSeconds: 5,
            purpose: .displayResolutionList
        )
        guard let result = try? await commandRunner.run(request) else { return nil }
        return result.stdout
    }

    private func runDisplayplacer(_ config: String) async {
        guard fileExists(displayplacerURL.path) else { return }
        let request = CommandRequest(
            executableURL: displayplacerURL,
            arguments: [config],
            environment: [:],
            timeoutSeconds: 5,
            purpose: .displayResolutionSet
        )
        _ = try? await commandRunner.run(request)
    }
}

// MARK: - Wine Steam Service

enum WineSteamError: Error {
    case readinessTimeout
}

protocol WineSteamServicing: Sendable {
    func launch(bottleName: String) async throws
    func waitForReadiness(timeout: TimeInterval) async throws
}

struct WineSteamService: WineSteamServicing {
    private static let steamExeArg = "C:\\Program Files (x86)\\Steam\\steam.exe"
    private static let checkInterval: TimeInterval = 0.5

    private let commandRunner: any CommandRunning
    private let wineURL: URL
    private let environmentProvider: @Sendable () -> [String: String]
    private let readinessBufferNanoseconds: UInt64
    private let sleep: @Sendable (UInt64) async throws -> Void

    init(
        commandRunner: (any CommandRunning)? = nil,
        wineURL: URL = Self.defaultCrossOverURL,
        environmentProvider: @escaping @Sendable () -> [String: String] = { ProcessInfo.processInfo.environment },
        readinessBufferNanoseconds: UInt64 = 2_000_000_000,
        sleep: @escaping @Sendable (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) }
    ) {
        self.wineURL = wineURL
        self.commandRunner = commandRunner ?? ProcessCommandRunner(
            allowedExecutableURLs: [
                wineURL,
                GameProcessMonitor.pgrepURL
            ]
        )
        self.environmentProvider = environmentProvider
        self.readinessBufferNanoseconds = readinessBufferNanoseconds
        self.sleep = sleep
    }

    func launch(bottleName: String) async throws {
        var env = environmentProvider()
        env["WINEDEBUG"] = "-all"
        let request = CommandRequest(
            executableURL: wineURL,
            arguments: ["--bottle", bottleName, Self.steamExeArg],
            environment: env,
            timeoutSeconds: 5,
            purpose: .wineSteamLaunch
        )
        _ = try await commandRunner.run(request)
    }

    func waitForReadiness(timeout: TimeInterval) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            // Wine processes appear in the OS process table but not in NSWorkspace.
            let running = await isSteamProcessRunning()
            if running {
                try await sleep(readinessBufferNanoseconds)
                return
            }
            try await sleep(UInt64(Self.checkInterval * 1_000_000_000))
        }
        throw WineSteamError.readinessTimeout
    }

    private func isSteamProcessRunning() async -> Bool {
        await GameProcessMonitor.isProcessRunning(
            name: "steam.exe",
            commandRunner: commandRunner
        )
    }

    private static var defaultCrossOverURL: URL {
        CrossOverExecutableResolver().resolve() ?? CrossOverExecutableResolver.defaultAllowedURLs[0]
    }
}

// MARK: - Game Process Monitor

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
