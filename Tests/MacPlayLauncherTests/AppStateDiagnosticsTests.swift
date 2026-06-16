import XCTest
@testable import MacPlayLauncher

@MainActor
final class AppStateDiagnosticsTests: XCTestCase {
    func testCanRunManualRealDiagnosticCheckWhenProductionPolicyConfigured() {
        let appState = makeAppState(policy: .production)

        XCTAssertTrue(appState.canRunManualRealDiagnosticCheck)
    }

    func testCannotRunManualRealDiagnosticCheckWithoutPolicy() {
        let appState = makeAppState(policy: nil)

        XCTAssertFalse(appState.canRunManualRealDiagnosticCheck)
    }

    func testLoadRuntimeDiagnosticSummaryUsesRequestedMode() async {
        let appState = makeAppState(policy: .production)

        let staticSummary = await appState.loadRuntimeDiagnosticSummary(mode: .staticOnly)
        XCTAssertEqual(staticSummary.source, .staticPreparation)
        XCTAssertEqual(staticSummary.dependencies.first(where: { $0.kind == .wine })?.status, .missing)

        let realSummary = await appState.loadRuntimeDiagnosticSummary(mode: .realReadOnly)
        XCTAssertEqual(realSummary.source, .realSystemCheck)
        XCTAssertEqual(realSummary.dependencies.first(where: { $0.kind == .wine })?.status, .ready)
    }

    private func makeAppState(policy: DiagnosticActivationPolicy?) -> AppState {
        let diagnosticService = SelectableDependencyDiagnosticService(
            mode: .staticOnly,
            policy: policy ?? .production,
            staticService: FakeDependencyDiagnosticService(
                summary: RuntimeDiagnosticSummary(
                    dependencies: [makeDependency(kind: .wine, status: .missing)]
                )
            ),
            realService: FakeDependencyDiagnosticService(
                summary: RuntimeDiagnosticSummary(
                    dependencies: [makeDependency(kind: .wine, status: .ready)]
                )
            )
        )

        return AppState(
            environment: AppEnvironment(
                profileManager: GameProfileManager(
                    store: JSONStore<GameProfile>(
                        directoryURL: FileManager.default.temporaryDirectory,
                        fileSystem: LocalFileSystem()
                    )
                ),
                bundledProfileLoader: BundledGameProfileLoader(bundle: .main),
                fileSelectionService: FakeFileSelectionService(folderURL: nil, executableURL: nil),
                bookmarkManager: FakeBookmarkManager(),
                gameFolderDetector: GameFolderDetector(fileSystem: LocalFileSystem()),
                dependencyDiagnosticService: diagnosticService,
                diagnosticActivationPolicy: policy,
                runReadinessEvaluator: DefaultRunReadinessEvaluator()
            )
        )
    }

    private func makeDependency(
        kind: RuntimeDependencyKind,
        status: RuntimeDependencyStatus
    ) -> RuntimeDependency {
        RuntimeDependency(
            displayName: kind.rawValue,
            kind: kind,
            status: status,
            version: nil,
            installPath: nil,
            userFacingDescription: "test",
            missingReason: nil,
            suggestedAction: nil,
            setupGuide: nil
        )
    }
}

private struct FakeDependencyDiagnosticService: DependencyDiagnosticServicing {
    let summary: RuntimeDiagnosticSummary

    func loadSummary(profiles: [GameProfile]) async -> RuntimeDiagnosticSummary {
        summary
    }
}

private struct FakeFileSelectionService: FileSelectionServicing {
    let folderURL: URL?
    let executableURL: URL?

    func selectGameFolder() -> URL? { folderURL }
    func selectExecutableFile() -> URL? { executableURL }
}

private struct FakeBookmarkManager: BookmarkManaging {
    func createBookmark(for url: URL) throws -> Data { Data([1]) }
    func resolveBookmark(_ data: Data) throws -> URL { URL(fileURLWithPath: "/tmp/fake") }
}
