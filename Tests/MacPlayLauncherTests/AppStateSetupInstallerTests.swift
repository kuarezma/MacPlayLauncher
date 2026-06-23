@testable import MacPlayLauncher
import XCTest

@MainActor
final class AppStateSetupInstallerTests: XCTestCase {
    func testPerformSetupActionStoresWaitingForUserState() async throws {
        let setupStep = SetupStep(
            id: "displayplacer",
            title: "Ekran çözünürlüğü yönetimi",
            explanation: "test",
            status: .needsAction(message: "missing"),
            canAutoFix: true,
            automationTarget: .displayplacer,
            actionLabel: "Otomatik Kur",
            externalURL: nil,
            copyCommand: "brew install displayplacer"
        )
        let installer = FakeSetupInstallerService(
            result: .waitingForUser("Homebrew kurulumu Terminal'de açıldı.")
        )
        let appState = try makeAppState(
            setupService: FakeCossacksSetupService(steps: [setupStep]),
            installerService: installer
        )

        await appState.refreshSetupStatus()
        await appState.performSetupAction(for: setupStep)

        XCTAssertEqual(installer.installedTargets, [.displayplacer])
        XCTAssertEqual(appState.setupActionMessage, "Homebrew kurulumu Terminal'de açıldı.")
        let updatedStep = try XCTUnwrap(appState.setupSteps.first { $0.id == "displayplacer" })
        XCTAssertEqual(updatedStep.status, .waitingForUser(message: "Homebrew kurulumu Terminal'de açıldı."))
    }

    func testPerformSetupActionStoresFailureState() async throws {
        let setupStep = SetupStep(
            id: "bottle",
            title: "Oyun ortamı",
            explanation: "test",
            status: .needsAction(message: "missing"),
            canAutoFix: true,
            automationTarget: .bottle,
            actionLabel: "Bottle Oluştur",
            externalURL: nil,
            copyCommand: nil
        )
        let installer = FakeSetupInstallerService(error: SetupInstallerError.missingCrossOver)
        let appState = try makeAppState(
            setupService: FakeCossacksSetupService(steps: [setupStep]),
            installerService: installer
        )

        await appState.refreshSetupStatus()
        await appState.performSetupAction(for: setupStep)

        XCTAssertEqual(
            appState.setupPatchErrorMessage,
            "CrossOver bulunamadı. Önce CrossOver trial kurulumunu çalıştırın."
        )
        let updatedStep = try XCTUnwrap(appState.setupSteps.first { $0.id == "bottle" })
        XCTAssertEqual(
            updatedStep.status,
            SetupStepStatus.failed(
                message: "CrossOver bulunamadı. Önce CrossOver trial kurulumunu çalıştırın."
            )
        )
    }

    private func makeAppState(
        setupService: any CossacksSetupServicing,
        installerService: any SetupInstallerServicing
    ) throws -> AppState {
        let fileSystem = LocalFileSystem()
        let appSupportURL = try temporaryDirectory()
        return AppState(
            environment: AppEnvironment(
                profileManager: GameProfileManager(
                    store: JSONStore<GameProfile>(
                        directoryURL: appSupportURL.appending(path: "Profiles"),
                        fileSystem: fileSystem
                    )
                ),
                bundledProfileLoader: BundledGameProfileLoader(bundle: .main),
                fileSelectionService: FakeSetupFileSelectionService(),
                bookmarkManager: BookmarkManager(),
                gameFolderDetector: GameFolderDetector(fileSystem: fileSystem),
                dependencyDiagnosticService: StaticDependencyDiagnosticService(),
                runReadinessEvaluator: DefaultRunReadinessEvaluator(),
                prefixManager: PrefixManager(appSupportURL: appSupportURL, fileSystem: fileSystem),
                steamInstallService: FakeSteamInstallService(),
                cossacksSetupService: setupService,
                setupInstallerService: installerService,
                appSupportURL: appSupportURL
            )
        )
    }
}

private final class FakeSetupInstallerService: SetupInstallerServicing, @unchecked Sendable {
    private let result: SetupInstallResult?
    private let error: Error?
    private(set) var installedTargets: [SetupAutomationTarget] = []

    init(result: SetupInstallResult) {
        self.result = result
        self.error = nil
    }

    init(error: Error) {
        self.result = nil
        self.error = error
    }

    func install(target: SetupAutomationTarget) async throws -> SetupInstallResult {
        installedTargets.append(target)
        if let error {
            throw error
        }
        return result ?? .completed("Tamamlandı.")
    }
}

private struct FakeCossacksSetupService: CossacksSetupServicing {
    let steps: [SetupStep]

    func detectSteps() async -> [SetupStep] {
        steps
    }

    func applyShaderPatch() throws {}
}

private struct FakeSetupFileSelectionService: FileSelectionServicing {
    func selectGameFolder() -> URL? { nil }
    func selectExecutableFile() -> URL? { nil }
}
