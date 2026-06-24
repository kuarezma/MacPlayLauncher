import Foundation

// MARK: - Types

enum SetupStepStatus: Equatable, Sendable {
    case checking
    case installing(message: String)
    case waitingForUser(message: String)
    case ok(detail: String)
    case needsAction(message: String)
    case blocked(reason: String)
    case failed(message: String)

    var isOK: Bool {
        if case .ok = self { return true }
        return false
    }
}

enum SetupAutomationTarget: String, Equatable, Sendable {
    case rosetta
    case crossOver
    case bottle
    case steam
    case displayplacer
    case shaderPatch
}

struct SetupStep: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let explanation: String
    let status: SetupStepStatus
    let canAutoFix: Bool
    let automationTarget: SetupAutomationTarget?
    let actionLabel: String?
    let externalURL: URL?
    let copyCommand: String?

    init(
        id: String,
        title: String,
        explanation: String,
        status: SetupStepStatus,
        canAutoFix: Bool,
        automationTarget: SetupAutomationTarget? = nil,
        actionLabel: String?,
        externalURL: URL?,
        copyCommand: String?
    ) {
        self.id = id
        self.title = title
        self.explanation = explanation
        self.status = status
        self.canAutoFix = canAutoFix
        self.automationTarget = automationTarget
        self.actionLabel = actionLabel
        self.externalURL = externalURL
        self.copyCommand = copyCommand
    }
}

// MARK: - Protocol

protocol CossacksSetupServicing: Sendable {
    func detectSteps() async -> [SetupStep]
    func applyShaderPatch() throws
}

// MARK: - Implementation

struct CossacksSetupService: CossacksSetupServicing {

    private let localPortGameDirectory: URL

    init(localPortGameDirectory: URL? = nil) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        self.localPortGameDirectory = localPortGameDirectory ?? home.appending(
            path: "Cossacks3_Mac_Port/oyun_dosyalari",
            directoryHint: .isDirectory
        )
    }

    func detectSteps() async -> [SetupStep] {
        return [
            detectRosetta(),
            detectGameInstall(),
            detectShaderPatch(),
            detectMinimapFix(),
            detectDisplayPlacer()
        ]
    }

    func applyShaderPatch() throws {
        guard let shaderPath = findShaderPath() else {
            throw CossacksSetupError.gameNotFound
        }
        let patcher = ShaderPatchService(gameShaderPath: shaderPath)
        let needsFragmentPatch = !patcher.isAlreadyPatched()
        let needsUnitRepair = try patcher.needsUnitVertexShaderRepair()
        if needsFragmentPatch || needsUnitRepair {
            try patcher.createTimestampedBackup()
        }
        if needsUnitRepair {
            try patcher.repairUnitVertexShadersFromBestBackupIfAvailable()
        }
        if needsFragmentPatch {
            try patcher.createBackupIfNeeded()
            try patcher.apply()
        }
    }

    // MARK: - Detectors

    private func detectRosetta() -> SetupStep {
        let explanation = "Rosetta, Apple Silicon Mac'lerde bazı Intel tabanlı yardımcı bileşenleri çalıştırır."
            + " Yerel WineCX motoru ve bazı Intel tabanlı yardımcı bileşenler için gerekli olabilir."
            + " Uygulama Apple'ın resmi softwareupdate aracıyla kurulum başlatabilir."
        if CurrentSystemArchitectureProvider().architecture == .intel {
            return SetupStep(
                id: "rosetta",
                title: "Rosetta",
                explanation: explanation,
                status: .ok(detail: "Bu Mac'te Rosetta gerekli değil"),
                canAutoFix: false,
                actionLabel: nil,
                externalURL: nil,
                copyCommand: nil
            )
        }

        let installed = FileManager.default.fileExists(
            atPath: "/Library/Apple/usr/libexec/oah/libRosettaRuntime"
        )
        return SetupStep(
            id: "rosetta",
            title: "Rosetta",
            explanation: explanation,
            status: installed
                ? .ok(detail: "Rosetta kurulu")
                : .needsAction(message: "Rosetta kurulu değil — uygulama resmi kurulum aracını çalıştırabilir"),
            canAutoFix: !installed,
            automationTarget: installed ? nil : .rosetta,
            actionLabel: installed ? nil : "Rosetta'yı Kur",
            externalURL: nil,
            copyCommand: nil
        )
    }

    private func detectGameInstall() -> SetupStep {
        let explanation = "Cossacks 3, Steam üzerinden indirilir."
            + " Ücretsiz port klasöründeki oyun dosyaları bulunmalıdır."
            + " Bu adım tamamlandıktan sonra launcher oyunu otomatik bulacak."
        let localGameFound = findGameExecutable(in: localPortGameDirectory) != nil
        guard localGameFound else {
            return SetupStep(
                id: "gameInstall",
                title: "Cossacks 3 kurulumu",
                explanation: explanation,
                status: .blocked(reason: "Önce ücretsiz Cossacks 3 port klasörü hazırlanmalı"),
                canAutoFix: false,
                actionLabel: nil,
                externalURL: nil,
                copyCommand: nil
            )
        }

        return SetupStep(
            id: "gameInstall",
            title: "Cossacks 3 kurulumu",
            explanation: explanation,
            status: localGameFound
                ? .ok(detail: "Cossacks 3 kurulu bulundu")
                : .needsAction(message: "Oyun kurulu değil — Steam kurulumu ve giriş ekranı açılabilir"),
            canAutoFix: !localGameFound,
            automationTarget: localGameFound ? nil : .steam,
            actionLabel: localGameFound ? nil : "Steam'i Hazırla",
            externalURL: nil,
            copyCommand: nil
        )
    }

    private func detectShaderPatch() -> SetupStep {
        let explanation = "Cossacks 3 eski OpenGL/GLSL 1.20 grafik sistemi kullanıyor."
            + " Apple Silicon (M1–M4) işlemciler bu sistemi tam desteklemiyor."
            + " Bu yama; güvenli fragment/fx shader düzeltmeleriyle efektleri ve nesne görüntüsünü dengeliyor."
            + " Görünür birlik kemik vertex shader'larını yedekten geri yükler ve tekrar yazmaz."
            + " Tek tıkla otomatik uygulanır."
        guard let shaderPath = findShaderPath() else {
            return SetupStep(
                id: "shaderPatch",
                title: "Apple Silicon grafik yamaları",
                explanation: explanation,
                status: .blocked(reason: "Önce oyun kurulmalı"),
                canAutoFix: false,
                actionLabel: nil,
                externalURL: nil,
                copyCommand: nil
            )
        }

        let patcher = ShaderPatchService(gameShaderPath: shaderPath)
        let patched = patcher.isAlreadyPatched()
        return SetupStep(
            id: "shaderPatch",
            title: "Apple Silicon grafik yamaları",
            explanation: explanation,
            status: patched
                ? .ok(detail: "Grafik yamaları uygulanmış")
                : .needsAction(message: "Grafik yamaları henüz uygulanmamış — düzeltmek için butona tıkla"),
            canAutoFix: true,
            automationTarget: .shaderPatch,
            actionLabel: patched ? nil : "Yamayı Uygula",
            externalURL: nil,
            copyCommand: nil
        )
    }

    private func detectMinimapFix() -> SetupStep {
        let bmpExists: Bool
        if let bmpPath = findMinimapBMPPath() {
            bmpExists = FileManager.default.fileExists(atPath: bmpPath.path)
        } else {
            bmpExists = false
        }
        let explanation = "Minimap, ilk kez bir harita yüklendiğinde oyun tarafından otomatik oluşturulan"
            + " bir BMP dosyasına kaydedilir."
            + " Herhangi bir müdahale gerekmez; tek seferlik oyun içi harita yükleme yeterli."
        return SetupStep(
            id: "minimapFix",
            title: "Minimap verisi",
            explanation: explanation,
            status: bmpExists
                ? .ok(detail: "Minimap verisi mevcut")
                : .needsAction(message: "İlk harita yüklendiğinde otomatik oluşacak"),
            canAutoFix: false,
            actionLabel: nil,
            externalURL: nil,
            copyCommand: nil
        )
    }

    private func detectDisplayPlacer() -> SetupStep {
        let paths = [
            "/opt/homebrew/bin/displayplacer",
            "/usr/local/bin/displayplacer"
        ]
        let found = paths.contains { FileManager.default.fileExists(atPath: $0) }
        let explanation = "Oyun başlatılırken ekran otomatik olarak 1280×800 çözünürlüğe ayarlanır,"
            + " oyun kapanınca eski haline döner."
            + " Bu işlem için 'displayplacer' komut satırı aracı gerekiyor."
            + " Homebrew üzerinden tek komutla kurulabilir."
        let missingMsg = "displayplacer kurulu değil — Homebrew varsa otomatik kurulabilir"
        return SetupStep(
            id: "displayplacer",
            title: "Ekran çözünürlüğü yönetimi",
            explanation: explanation,
            status: found
                ? .ok(detail: "displayplacer kurulu")
                : .needsAction(message: missingMsg),
            canAutoFix: !found,
            automationTarget: found ? nil : .displayplacer,
            actionLabel: found ? nil : "Otomatik Kur",
            externalURL: nil,
            copyCommand: found ? nil : "brew install displayplacer"
        )
    }

    // MARK: - Path Helpers

    private func findGameExecutable(in bottlePath: URL) -> URL? {
        let candidates = [
            "cossacks.exe",
            "drive_c/Program Files (x86)/Steam/steamapps/common/Cossacks 3/cossacks.exe",
            "drive_c/Cossacks3/cossacks.exe",
            "drive_c/GOG Games/Cossacks 3/cossacks.exe"
        ]
        return candidates
            .map { bottlePath.appending(path: $0, directoryHint: .notDirectory) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }

    private func findShaderPath() -> URL? {
        let candidates = [
            localPortGameDirectory.appending(path: "data/shaders/obj", directoryHint: .isDirectory)
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    private func findMinimapBMPPath() -> URL? {
        let candidates = [
            localPortGameDirectory.appending(
                path: "data/gen/bitmap/ext/mac_minimap.bmp",
                directoryHint: .notDirectory
            )
        ]
        return candidates.first
    }
}

// MARK: - Errors

enum CossacksSetupError: Error, LocalizedError {
    case gameNotFound
    case patchFailed(String)

    var errorDescription: String? {
        switch self {
        case .gameNotFound:
            return "Oyun dizini bulunamadı. Ücretsiz Cossacks 3 port klasörünü kontrol edin."
        case .patchFailed(let reason):
            return "Yama uygulanamadı: \(reason)"
        }
    }
}
