import Foundation

enum SetupInstallResult: Equatable, Sendable {
    case completed(String)
    case waitingForUser(String)
}

protocol SetupInstallerServicing: Sendable {
    func install(target: SetupAutomationTarget) async throws -> SetupInstallResult
}

struct SetupInstallerService: SetupInstallerServicing {
    private static let bottleName = "Cossacks3"
    private static let steamSetupURL = URL(
        string: "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe"
    )!
    private static let crossOverAppURL = URL(fileURLWithPath: "/Applications/CrossOver.app")
    private static let cxbottleURL = URL(
        fileURLWithPath: "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/cxbottle"
    )
    private static let cxstartURL = URL(
        fileURLWithPath: "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver/bin/cxstart"
    )
    private static let openURL = URL(fileURLWithPath: "/usr/bin/open")
    private static let softwareUpdateURL = URL(fileURLWithPath: "/usr/sbin/softwareupdate")
    private static let homebrewInstallerCommand =
        #"/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)""#

    private let commandRunner: any CommandRunning
    private let fileChecker: any FileChecking
    private let steamExecutableURL: URL
    let offlineTxtURL: URL

    init(
        commandRunner: any CommandRunning = ProcessCommandRunner(),
        fileChecker: any FileChecking = FileManagerFileChecker(),
        steamExecutableURL: URL? = nil,
        offlineTxtURL: URL? = nil
    ) {
        self.commandRunner = commandRunner
        self.fileChecker = fileChecker
        self.steamExecutableURL = steamExecutableURL ?? Self.defaultSteamExecutableURL()
        self.offlineTxtURL = offlineTxtURL ?? Self.defaultOfflineTxtURL()
    }

    func install(target: SetupAutomationTarget) async throws -> SetupInstallResult {
        switch target {
        case .rosetta:
            try await installRosetta()
        case .crossOver:
            return try await installCrossOver()
        case .bottle:
            try await createBottle()
            return .completed("'Cossacks3' bottle oluşturuldu.")
        case .steam:
            return try await prepareSteam()
        case .displayplacer:
            return try await installDisplayplacer()
        case .shaderPatch:
            throw SetupInstallerError.unsupportedTarget("Grafik yaması ayrı servisle uygulanır.")
        case .offlineTxt:
            return try await disableOfflineTxt()
        }

        return .completed("Kurulum tamamlandı.")
    }

    private func installRosetta() async throws {
        try await run(
            executableURL: Self.softwareUpdateURL,
            arguments: ["--install-rosetta", "--agree-to-license"],
            timeoutSeconds: 600,
            purpose: .rosettaInstall
        )
    }

    private func installCrossOver() async throws -> SetupInstallResult {
        guard let brewURL = availableHomebrewURL() else {
            try await openHomebrewInstallerInTerminal()
            return .waitingForUser("Homebrew kurulumu Terminal'de açıldı. Kurulum bitince bu adımı tekrar çalıştırın.")
        }

        try await run(
            executableURL: brewURL,
            arguments: ["install", "--cask", "crossover"],
            timeoutSeconds: 1_800,
            purpose: .crossOverInstall
        )
        try? await openCrossOver()
        return .waitingForUser("CrossOver kuruldu. Açılan pencerede trial/lisans adımını onaylayın.")
    }

    private func installDisplayplacer() async throws -> SetupInstallResult {
        guard let brewURL = availableHomebrewURL() else {
            try await openHomebrewInstallerInTerminal()
            return .waitingForUser(
                "Homebrew kurulumu Terminal'de açıldı. Kurulum bitince displayplacer adımını tekrar çalıştırın."
            )
        }

        try await run(
            executableURL: brewURL,
            arguments: ["install", "displayplacer"],
            timeoutSeconds: 900,
            purpose: .displayplacerInstall
        )
        return .completed("displayplacer kuruldu.")
    }

    private func createBottle() async throws {
        guard fileChecker.fileExists(at: Self.crossOverAppURL) else {
            throw SetupInstallerError.missingCrossOver
        }
        guard fileChecker.isExecutableFile(at: Self.cxbottleURL) else {
            throw SetupInstallerError.missingCrossOverTool("cxbottle")
        }

        try await run(
            executableURL: Self.cxbottleURL,
            arguments: ["--bottle", Self.bottleName, "--create", "--template", "win10_64"],
            timeoutSeconds: 900,
            purpose: .bottleCreate
        )
    }

    private func prepareSteam() async throws -> SetupInstallResult {
        guard fileChecker.isExecutableFile(at: Self.cxstartURL) else {
            throw SetupInstallerError.missingCrossOverTool("cxstart")
        }

        if steamExecutableExists() {
            try await run(
                executableURL: Self.cxstartURL,
                arguments: [
                    "--bottle",
                    Self.bottleName,
                    "--no-wait",
                    #"C:\Program Files (x86)\Steam\steam.exe"#
                ],
                timeoutSeconds: 30,
                purpose: .steamSetup
            )
            return .waitingForUser("Steam açıldı. Hesabınıza giriş yapın; ardından Cossacks 3 kurulumu başlatılabilir.")
        }

        let installerURL = try await downloadSteamSetup()
        try await run(
            executableURL: Self.cxstartURL,
            arguments: ["--bottle", Self.bottleName, "--no-wait", installerURL.path],
            timeoutSeconds: 60,
            purpose: .steamSetup
        )
        return .waitingForUser("Steam kurucusu CrossOver içinde açıldı. Kurulum bitince Steam giriş ekranı gelecektir.")
    }

    private func openHomebrewInstallerInTerminal() async throws {
        let scriptURL = try makeHomebrewInstallerScript()
        try await run(
            executableURL: Self.openURL,
            arguments: [scriptURL.path],
            timeoutSeconds: 10,
            purpose: .homebrewInstallPrompt
        )
    }

    private func openCrossOver() async throws {
        try await run(
            executableURL: Self.openURL,
            arguments: ["-a", "CrossOver"],
            timeoutSeconds: 10,
            purpose: .crossOverOpen
        )
    }

    private func availableHomebrewURL() -> URL? {
        [
            URL(fileURLWithPath: "/opt/homebrew/bin/brew"),
            URL(fileURLWithPath: "/usr/local/bin/brew")
        ].first { fileChecker.fileExists(at: $0) && fileChecker.isExecutableFile(at: $0) }
    }

    private func steamExecutableExists() -> Bool {
        fileChecker.fileExists(at: steamExecutableURL)
    }

    private static func defaultSteamExecutableURL() -> URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let steamPath = "Library/Application Support/CrossOver/Bottles/\(Self.bottleName)"
            + "/drive_c/Program Files (x86)/Steam/steam.exe"
        return home.appending(
            path: steamPath,
            directoryHint: .notDirectory
        )
    }

    private func downloadSteamSetup() async throws -> URL {
        try await Task.detached(priority: .utility) {
            let data = try Data(contentsOf: Self.steamSetupURL)
            let targetURL = FileManager.default.temporaryDirectory
                .appending(path: "MacPlayLauncher-SteamSetup.exe", directoryHint: .notDirectory)
            try data.write(to: targetURL, options: .atomic)
            return targetURL
        }.value
    }

    private func disableOfflineTxt() async throws -> SetupInstallResult {
        guard fileChecker.fileExists(at: offlineTxtURL) else {
            return .completed("Çevrimdışı kısıtlaması zaten yok.")
        }
        let disabledURL = offlineTxtURL.deletingLastPathComponent()
            .appending(path: "offline.txt.disabled", directoryHint: .notDirectory)
        do {
            if fileChecker.fileExists(at: disabledURL) {
                try FileManager.default.removeItem(at: disabledURL)
            }
            try FileManager.default.moveItem(at: offlineTxtURL, to: disabledURL)
            return .completed("Çevrimdışı kısıtlaması devre dışı bırakıldı.")
        } catch {
            let manualCmd = "mv '\(offlineTxtURL.path)' '\(disabledURL.path)'"
            return .waitingForUser(
                "Dosya yeniden adlandırılamadı. Terminalde şu komutu çalıştırın: \(manualCmd)"
            )
        }
    }

    private static func defaultOfflineTxtURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appending(
                path: "Cossacks3_Mac_Port/oyun_dosyalari/steam_settings/offline.txt",
                directoryHint: .notDirectory
            )
    }

    private func makeHomebrewInstallerScript() throws -> URL {
        let scriptURL = FileManager.default.temporaryDirectory
            .appending(path: "MacPlayLauncher-Homebrew-Install.command", directoryHint: .notDirectory)
        let script = """
        #!/bin/zsh
        echo "MacPlay Launcher Homebrew kurulumunu başlatıyor."
        echo "Komut resmi Homebrew kurulum adresinden çalıştırılır:"
        echo "\(Self.homebrewInstallerCommand)"
        echo ""
        \(Self.homebrewInstallerCommand)
        echo ""
        echo "Kurulum bittiyse MacPlay Launcher'a dönüp Yenile düğmesine basın."
        read -k 1 "?Kapatmak için bir tuşa basın..."
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: scriptURL.path
        )
        return scriptURL
    }

    @discardableResult
    private func run(
        executableURL: URL,
        arguments: [String],
        timeoutSeconds: TimeInterval,
        purpose: CommandPurpose
    ) async throws -> CommandResult {
        try await commandRunner.run(
            CommandRequest(
                executableURL: executableURL,
                arguments: arguments,
                environment: [:],
                timeoutSeconds: timeoutSeconds,
                purpose: purpose
            )
        )
    }
}

enum SetupInstallerError: Error, LocalizedError, Equatable {
    case missingCrossOver
    case missingCrossOverTool(String)
    case unsupportedTarget(String)

    var errorDescription: String? {
        switch self {
        case .missingCrossOver:
            return "CrossOver bulunamadı. Önce CrossOver trial kurulumunu çalıştırın."
        case .missingCrossOverTool(let tool):
            return "CrossOver aracı bulunamadı: \(tool). CrossOver kurulumunu kontrol edin."
        case .unsupportedTarget(let message):
            return message
        }
    }
}
