@testable import MacPlayLauncher
import XCTest

final class SelectableDiagnosticServiceTests: XCTestCase {
    func testStaticModeReturnsStaticSummaryWithSourceLabel() async {
        let staticDependency = makeDependency(kind: .wine, status: .missing)
        let service = SelectableDependencyDiagnosticService(
            mode: .staticOnly,
            policy: .production,
            staticService: FakeDependencyDiagnosticService(
                summary: RuntimeDiagnosticSummary(dependencies: [staticDependency])
            ),
            realService: FakeDependencyDiagnosticService(
                summary: RuntimeDiagnosticSummary(dependencies: [makeDependency(kind: .wine, status: .ready)])
            )
        )

        let summary = await service.loadSummary(profiles: [])

        XCTAssertEqual(summary.source, .staticPreparation)
        XCTAssertEqual(summary.dependencies.first?.status, .missing)
    }

    func testRealModeReturnsRealSummaryWhenPolicyAllows() async {
        let realDependency = makeDependency(kind: .rosetta, status: .ready)
        let service = SelectableDependencyDiagnosticService(
            mode: .realReadOnly,
            policy: .internalRealReadOnly,
            staticService: FakeDependencyDiagnosticService(
                summary: RuntimeDiagnosticSummary(dependencies: [makeDependency(kind: .rosetta, status: .missing)])
            ),
            realService: FakeDependencyDiagnosticService(
                summary: RuntimeDiagnosticSummary(dependencies: [realDependency])
            )
        )

        let summary = await service.loadSummary(profiles: [])

        XCTAssertEqual(summary.source, .realSystemCheck)
        XCTAssertEqual(summary.dependencies.first?.status, .ready)
    }

    func testRealModeFallsBackToStaticWhenPolicyBlocksRealDiagnostics() async {
        let staticDependency = makeDependency(kind: .wine, status: .missing)
        let blockedPolicy = DiagnosticActivationPolicy(
            defaultMode: .staticOnly,
            allowsRealDiagnostics: false,
            requiresExplicitUserAction: true
        )
        let service = SelectableDependencyDiagnosticService(
            mode: .realReadOnly,
            policy: blockedPolicy,
            staticService: FakeDependencyDiagnosticService(
                summary: RuntimeDiagnosticSummary(dependencies: [staticDependency])
            ),
            realService: FakeDependencyDiagnosticService(
                summary: RuntimeDiagnosticSummary(dependencies: [makeDependency(kind: .wine, status: .ready)])
            )
        )

        let summary = await service.loadSummary(profiles: [])

        XCTAssertEqual(summary.source, .staticPreparation)
        XCTAssertEqual(summary.dependencies.first?.status, .missing)
    }

    func testRequestedModeOverridesStoredMode() async {
        let service = SelectableDependencyDiagnosticService(
            mode: .staticOnly,
            policy: .production,
            staticService: FakeDependencyDiagnosticService(
                summary: RuntimeDiagnosticSummary(dependencies: [makeDependency(kind: .wine, status: .missing)])
            ),
            realService: FakeDependencyDiagnosticService(
                summary: RuntimeDiagnosticSummary(dependencies: [makeDependency(kind: .wine, status: .ready)])
            )
        )

        let realSummary = await service.loadSummary(profiles: [], mode: .realReadOnly)

        XCTAssertEqual(realSummary.source, .realSystemCheck)
        XCTAssertEqual(realSummary.dependencies.first?.status, .ready)

        let staticSummary = await service.loadSummary(profiles: [], mode: .staticOnly)

        XCTAssertEqual(staticSummary.source, .staticPreparation)
        XCTAssertEqual(staticSummary.dependencies.first?.status, .missing)
    }

    func testRealModeKeepsPassiveDXVKAndMoltenVKFromRealService() async {
        let service = SelectableDependencyDiagnosticService(
            mode: .realReadOnly,
            policy: .internalRealReadOnly,
            staticService: FakeDependencyDiagnosticService(summary: RuntimeDiagnosticSummary(dependencies: [])),
            realService: RealDependencyDiagnosticService(
                rosettaProvider: FakeRuntimeDiagnosticProvider(
                    dependency: makeDependency(kind: .rosetta, status: .ready)
                ),
                wineProvider: FakeRuntimeDiagnosticProvider(
                    dependency: makeDependency(kind: .wine, status: .ready)
                ),
                dxvkProvider: FakeRuntimeDiagnosticProvider(
                    dependency: makeDependency(kind: .dxvk, status: .missing)
                ),
                moltenVKProvider: FakeRuntimeDiagnosticProvider(
                    dependency: makeDependency(kind: .moltenVK, status: .missing)
                )
            )
        )

        let summary = await service.loadSummary(profiles: [])

        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .dxvk })?.status, .missing)
        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .moltenVK })?.status, .missing)
    }

    func testRealModeWithUnknownProviderStillReturnsSummary() async {
        let service = SelectableDependencyDiagnosticService(
            mode: .realReadOnly,
            policy: .internalRealReadOnly,
            staticService: FakeDependencyDiagnosticService(summary: RuntimeDiagnosticSummary(dependencies: [])),
            realService: RealDependencyDiagnosticService(
                rosettaProvider: FakeRuntimeDiagnosticProvider(
                    dependency: makeDependency(kind: .rosetta, status: .unknown)
                ),
                wineProvider: FakeRuntimeDiagnosticProvider(
                    dependency: makeDependency(kind: .wine, status: .ready)
                ),
                dxvkProvider: FakeRuntimeDiagnosticProvider(
                    dependency: makeDependency(kind: .dxvk, status: .notRequired)
                ),
                moltenVKProvider: FakeRuntimeDiagnosticProvider(
                    dependency: makeDependency(kind: .moltenVK, status: .notRequired)
                )
            )
        )

        let summary = await service.loadSummary(profiles: [configuredProfile()])

        XCTAssertEqual(summary.source, .realSystemCheck)
        XCTAssertEqual(summary.overallStatus, .unknown)
        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .rosetta })?.status, .unknown)
    }

    private func configuredProfile() -> GameProfile {
        GameProfile(
            schemaVersion: GameProfile.currentSchemaVersion,
            id: "configured-cossacks3",
            displayName: "Cossacks 3",
            executablePath: "/Games/Cossacks/cossacks3.exe",
            workingDirectory: "/Games/Cossacks",
            prefixPath: "Prefixes/configured-cossacks3",
            executableBookmarkData: Data([1]),
            workingDirectoryBookmarkData: Data([2]),
            runtime: .wineDXVKMoltenVK,
            performanceMode: .balanced,
            wineArch: .win64,
            windowsVersion: .win10,
            dependencies: [],
            environment: [:],
            launchArguments: [],
            knownIssues: [],
            lastPlayedAt: nil,
            totalPlayTimeMinutes: 0,
            launchCount: 0
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
            missingReason: status == .missing ? "missing" : nil,
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

private struct FakeRuntimeDiagnosticProvider: RuntimeDiagnosticProviding {
    let dependency: RuntimeDependency

    func diagnose() async -> RuntimeDependency {
        dependency
    }
}
