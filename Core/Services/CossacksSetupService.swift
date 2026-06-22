import Foundation

// MARK: - Types

enum SetupStepStatus: Equatable, Sendable {
    case checking
    case ok(detail: String)
    case needsAction(message: String)
    case blocked(reason: String)

    var isOK: Bool {
        if case .ok = self { return true }
        return false
    }
}

struct SetupStep: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let explanation: String
    let status: SetupStepStatus
    let canAutoFix: Bool
    let actionLabel: String?
    let externalURL: URL?
    let copyCommand: String?
}

// MARK: - Protocol

protocol CossacksSetupServicing: Sendable {
    func detectSteps() async -> [SetupStep]
    func applyShaderPatch() throws
}

// MARK: - Implementation

struct CossacksSetupService: CossacksSetupServicing {

    private static let crossOverAppPath = "/Applications/CrossOver.app"
    private static let bottleName = "Cossacks3"
    private static let bottleBase = "Library/Application Support/CrossOver/Bottles"

    func detectSteps() async -> [SetupStep] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let bottlePath = home.appending(path: "\(Self.bottleBase)/\(Self.bottleName)", directoryHint: .isDirectory)

        return [
            detectCrossOver(),
            detectBottle(bottlePath: bottlePath),
            detectGameInstall(bottlePath: bottlePath),
            detectShaderPatch(bottlePath: bottlePath),
            detectMinimapFix(bottlePath: bottlePath),
            detectDisplayPlacer()
        ]
    }

    func applyShaderPatch() throws {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let bottlePath = home.appending(path: "\(Self.bottleBase)/\(Self.bottleName)", directoryHint: .isDirectory)
        guard let shaderPath = findShaderPath(in: bottlePath) else {
            throw CossacksSetupError.gameNotFound
        }
        let patcher = ShaderPatchService(gameShaderPath: shaderPath)
        if !patcher.isAlreadyPatched() {
            try patcher.createBackupIfNeeded()
            try patcher.apply()
        }
    }

    // MARK: - Detectors

    private func detectCrossOver() -> SetupStep {
        let exists = FileManager.default.fileExists(atPath: Self.crossOverAppPath)
        return SetupStep(
            id: "crossover",
            title: "CrossOver",
            explanation: "CrossOver, Windows oyunlarını Mac'te çalıştıran bir uygulama. Cossacks 3'ün macOS'ta çalışabilmesi için CrossOver kurulu olması gerekiyor. CrossOver, yüklü oyunlara izole bir Windows ortamı (bottle) sağlıyor.",
            status: exists
                ? .ok(detail: "CrossOver kurulu")
                : .needsAction(message: "CrossOver kurulu değil — indirme sayfasını açın"),
            canAutoFix: false,
            actionLabel: exists ? nil : "CrossOver İndir",
            externalURL: exists ? nil : URL(string: "https://www.codeweavers.com/crossover"),
            copyCommand: nil
        )
    }

    private func detectBottle(bottlePath: URL) -> SetupStep {
        let exists = FileManager.default.fileExists(atPath: bottlePath.path)
        return SetupStep(
            id: "bottle",
            title: "Oyun ortamı (Bottle)",
            explanation: "CrossOver, her uygulama için 'bottle' adlı izole bir Windows ortamı oluşturur. Cossacks 3 için 'Cossacks3' adlı, Windows 10 64-bit hedefli bir bottle gerekiyor. CrossOver uygulamasından kolayca oluşturulabilir.",
            status: exists
                ? .ok(detail: "'Cossacks3' bottle mevcut")
                : .needsAction(message: "CrossOver'da 'Cossacks3' adlı yeni bir bottle oluşturun (Windows 10, 64-bit)"),
            canAutoFix: false,
            actionLabel: exists ? nil : "CrossOver'ı Aç",
            externalURL: exists ? nil : URL(string: "crossover://install"),
            copyCommand: nil
        )
    }

    private func detectGameInstall(bottlePath: URL) -> SetupStep {
        guard FileManager.default.fileExists(atPath: bottlePath.path) else {
            return SetupStep(
                id: "gameInstall",
                title: "Cossacks 3 kurulumu",
                explanation: "Cossacks 3, Steam üzerinden indirilir. Steam'i CrossOver bottle'ına kurmanız ve ardından Cossacks 3'ü Steam'den indirmeniz gerekiyor. Bu adım tamamlandıktan sonra launcher oyunu otomatik bulacak.",
                status: .blocked(reason: "Önce bottle oluşturulmalı"),
                canAutoFix: false,
                actionLabel: nil,
                externalURL: nil,
                copyCommand: nil
            )
        }

        let exeFound = findGameExecutable(in: bottlePath) != nil
        return SetupStep(
            id: "gameInstall",
            title: "Cossacks 3 kurulumu",
            explanation: "Cossacks 3, Steam üzerinden indirilir. Steam'i CrossOver bottle'ına kurmanız ve ardından Cossacks 3'ü Steam'den indirmeniz gerekiyor. Bu adım tamamlandıktan sonra launcher oyunu otomatik bulacak.",
            status: exeFound
                ? .ok(detail: "Cossacks 3 kurulu bulundu")
                : .needsAction(message: "Oyun kurulu değil — Steam ile bottle'a yükleyin"),
            canAutoFix: false,
            actionLabel: exeFound ? nil : "Steam Mağazasını Aç",
            externalURL: exeFound ? nil : URL(string: "https://store.steampowered.com/app/333420"),
            copyCommand: nil
        )
    }

    private func detectShaderPatch(bottlePath: URL) -> SetupStep {
        guard let shaderPath = findShaderPath(in: bottlePath) else {
            return SetupStep(
                id: "shaderPatch",
                title: "Apple Silicon grafik yamaları",
                explanation: "Cossacks 3 eski OpenGL/GLSL 1.20 grafik sistemi kullanıyor. Apple Silicon (M1–M4) işlemciler bu sistemi tam desteklemiyor. Bu yama; atlı birlik animasyonlarını, savaş efektlerini ve nesne görüntüsünü düzeltiyor. Tek tıkla otomatik uygulanır.",
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
            explanation: "Cossacks 3 eski OpenGL/GLSL 1.20 grafik sistemi kullanıyor. Apple Silicon (M1–M4) işlemciler bu sistemi tam desteklemiyor. Bu yama; atlı birlik animasyonlarını, savaş efektlerini ve nesne görüntüsünü düzeltiyor. Tek tıkla otomatik uygulanır.",
            status: patched
                ? .ok(detail: "Grafik yamaları uygulanmış")
                : .needsAction(message: "Grafik yamaları henüz uygulanmamış — düzeltmek için butona tıkla"),
            canAutoFix: true,
            actionLabel: patched ? nil : "Yamayı Uygula",
            externalURL: nil,
            copyCommand: nil
        )
    }

    private func detectMinimapFix(bottlePath: URL) -> SetupStep {
        let bmpExists: Bool
        if let bmpPath = findMinimapBMPPath(in: bottlePath) {
            bmpExists = FileManager.default.fileExists(atPath: bmpPath.path)
        } else {
            bmpExists = false
        }
        return SetupStep(
            id: "minimapFix",
            title: "Minimap verisi",
            explanation: "Minimap, ilk kez bir harita yüklendiğinde oyun tarafından otomatik oluşturulan bir BMP dosyasına kaydedilir. Herhangi bir müdahale gerekmez; tek seferlik oyun içi harita yükleme yeterli.",
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
        return SetupStep(
            id: "displayplacer",
            title: "Ekran çözünürlüğü yönetimi",
            explanation: "Oyun başlatılırken ekran otomatik olarak 1280×800 çözünürlüğe ayarlanır, oyun kapanınca eski haline döner. Bu işlem için 'displayplacer' komut satırı aracı gerekiyor. Homebrew üzerinden tek komutla kurulabilir.",
            status: found
                ? .ok(detail: "displayplacer kurulu")
                : .needsAction(message: "displayplacer kurulu değil — aşağıdaki komutu terminale yapıştırın"),
            canAutoFix: false,
            actionLabel: found ? nil : "Komutu Kopyala",
            externalURL: nil,
            copyCommand: found ? nil : "brew install jakehilborn/jakehilborn/displayplacer"
        )
    }

    // MARK: - Path Helpers

    private func findGameExecutable(in bottlePath: URL) -> URL? {
        let candidates = [
            "drive_c/Program Files (x86)/Steam/steamapps/common/Cossacks 3/cossacks.exe",
            "drive_c/Cossacks3/cossacks.exe",
            "drive_c/GOG Games/Cossacks 3/cossacks.exe"
        ]
        return candidates
            .map { bottlePath.appending(path: $0, directoryHint: .notDirectory) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }

    private func findShaderPath(in bottlePath: URL) -> URL? {
        let candidates = [
            "drive_c/Program Files (x86)/Steam/steamapps/common/Cossacks 3/data/shaders/obj",
            "drive_c/Cossacks3/data/shaders/obj",
            "drive_c/GOG Games/Cossacks 3/data/shaders/obj"
        ]
        return candidates
            .map { bottlePath.appending(path: $0, directoryHint: .isDirectory) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }

    private func findMinimapBMPPath(in bottlePath: URL) -> URL? {
        let candidates = [
            "drive_c/Program Files (x86)/Steam/steamapps/common/Cossacks 3/data/gen/bitmap/ext/mac_minimap.bmp",
            "drive_c/Cossacks3/data/gen/bitmap/ext/mac_minimap.bmp"
        ]
        return candidates
            .map { bottlePath.appending(path: $0, directoryHint: .notDirectory) }
            .first
    }
}

// MARK: - Errors

enum CossacksSetupError: Error, LocalizedError {
    case gameNotFound
    case patchFailed(String)

    var errorDescription: String? {
        switch self {
        case .gameNotFound:
            return "Oyun dizini bulunamadı. Cossacks 3'ün CrossOver bottle'ına kurulu olduğundan emin olun."
        case .patchFailed(let reason):
            return "Yama uygulanamadı: \(reason)"
        }
    }
}
