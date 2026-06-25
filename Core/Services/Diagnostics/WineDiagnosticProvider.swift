import Foundation

private struct WineDependencyParams {
    let status: RuntimeDependencyStatus
    let version: String?
    let installPath: String?
    let description: String
    let missingReason: String?
    let suggestedAction: String?
}

struct WineDiagnosticProvider: RuntimeDiagnosticProviding {
    private let commandRunner: any CommandRunning
    private let fileChecker: any FileChecking
    private let allowedWineURLs: [URL]
    private let timeoutSeconds: TimeInterval

    init(
        commandRunner: any CommandRunning = ProcessCommandRunner(),
        fileChecker: any FileChecking = FileManagerFileChecker(),
        allowedWineURLs: [URL] = Self.defaultAllowedWineURLs,
        timeoutSeconds: TimeInterval = 2
    ) {
        self.commandRunner = commandRunner
        self.fileChecker = fileChecker
        self.allowedWineURLs = allowedWineURLs
        self.timeoutSeconds = timeoutSeconds
    }

    func diagnose() async -> RuntimeDependency {
        guard let wineURL = allowedWineURLs.first(where: isUsableWineExecutable) else {
            return dependency(WineDependencyParams(
                status: .missing,
                version: nil,
                installPath: nil,
                description: "Wine bulunamadı.",
                missingReason: "Wine bulunamadı.",
                suggestedAction: "Wine’ı desteklenen konumlardan birine manuel olarak kurmanız gerekir."
            ))
        }

        do {
            let result = try await commandRunner.run(commandRequest(for: wineURL))
            let version = Self.parseVersion(from: result.stdout)
                ?? Self.parseVersion(from: result.stderr)
            return dependency(WineDependencyParams(
                status: .ready,
                version: version,
                installPath: wineURL.path,
                description: version == nil
                    ? "Wine bulundu ancak sürüm bilgisi ayrıştırılamadı."
                    : "Wine bulundu ve sürüm bilgisi okunabildi.",
                missingReason: nil,
                suggestedAction: nil
            ))
        } catch {
            return dependency(WineDependencyParams(
                status: .unknown,
                version: nil,
                installPath: wineURL.path,
                description: "Wine durumu doğrulanamadı.",
                missingReason: "Wine durumu doğrulanamadı.",
                suggestedAction: "Wine kurulumunu ve çalıştırılabilir dosya izinlerini kontrol edin."
            ))
        }
    }

    static func parseVersion(from stdout: String) -> String? {
        let trimmedOutput = stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedOutput.hasPrefix("wine-") else {
            return nil
        }

        let version = trimmedOutput.dropFirst("wine-".count)
        return version.isEmpty ? nil : String(version)
    }

    private func isUsableWineExecutable(_ url: URL) -> Bool {
        fileChecker.fileExists(at: url) && fileChecker.isExecutableFile(at: url)
    }

    private func commandRequest(for wineURL: URL) -> CommandRequest {
        CommandRequest(
            executableURL: wineURL,
            arguments: ["--version"],
            environment: [:],
            timeoutSeconds: timeoutSeconds,
            purpose: .wineVersionCheck
        )
    }

    private func dependency(_ params: WineDependencyParams) -> RuntimeDependency {
        RuntimeDependency(
            displayName: "Wine",
            kind: .wine,
            status: params.status,
            version: params.version,
            installPath: params.installPath,
            userFacingDescription: params.description,
            missingReason: params.missingReason,
            suggestedAction: params.suggestedAction,
            setupGuide: nil
        )
    }

    private static var defaultAllowedWineURLs: [URL] {
        [
            URL(fileURLWithPath: "/opt/homebrew/bin/wine"),
            URL(fileURLWithPath: "/usr/local/bin/wine")
        ]
    }
}
