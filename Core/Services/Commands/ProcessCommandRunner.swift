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

    private static func normalizedURL(_ url: URL) -> URL {
        url.standardizedFileURL.resolvingSymlinksInPath()
    }

    private static func isShellExecutable(_ url: URL) -> Bool {
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
        [
            URL(fileURLWithPath: "/usr/bin/true"),
            URL(fileURLWithPath: "/usr/bin/arch"),
            URL(fileURLWithPath: "/opt/homebrew/bin/wine"),
            URL(fileURLWithPath: "/usr/local/bin/wine")
        ]
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
