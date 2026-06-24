import Foundation
@testable import MacPlayLauncher
import XCTest

final class RealDependencyDiagnosticServiceTests: XCTestCase {
    func testProviderResultsAreReflectedInSummary() async {
        let service = RealDependencyDiagnosticService(
            rosettaProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .rosetta, status: .ready)),
            wineProvider: FakeRuntimeDiagnosticProvider(
                dependency: dependency(kind: .wine, status: .ready, version: "9.0")
            ),
            dxvkProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .dxvk, status: .missing)),
            moltenVKProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .moltenVK, status: .missing))
        )

        let summary = await service.loadSummary(profiles: [configuredProfile()])

        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .rosetta })?.status, .ready)
        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .wine })?.version, "9.0")
        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .gameProfile })?.status, .ready)
    }

    func testDefaultPassiveProvidersKeepDXVKAndMoltenVKStatic() async {
        let service = RealDependencyDiagnosticService(
            rosettaProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .rosetta, status: .ready)),
            wineProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .wine, status: .ready))
        )

        let summary = await service.loadSummary(profiles: [configuredProfile()])

        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .dxvk })?.status, .missing)
        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .moltenVK })?.status, .missing)
        XCTAssertEqual(
            summary.dependencies.first(where: { $0.kind == .dxvk })?.missingReason,
            String(localized: "diagnostics.dxvk.notConfigured")
        )
    }

    func testConfiguredUserProfileMakesGameProfileReady() async {
        let service = makeService()

        let summary = await service.loadSummary(profiles: [configuredProfile()])

        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .gameProfile })?.status, .ready)
    }

    func testBundledSampleProfileRequiresUserSelectedLocalPaths() async {
        let service = makeService()

        let summary = await service.loadSummary(profiles: [GameProfile.sampleCossacks3])

        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .gameProfile })?.status, .missing)
    }

    func testBundledLocalProfileUsesRegularRuntimeDependencies() async {
        let service = RealDependencyDiagnosticService(
            rosettaProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .rosetta, status: .ready)),
            wineProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .wine, status: .missing)),
            dxvkProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .dxvk, status: .missing)),
            moltenVKProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .moltenVK, status: .missing))
        )

        let summary = await service.loadSummary(profiles: [GameProfile.sampleCossacks3])

        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .wine })?.status, .missing)
        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .dxvk })?.status, .missing)
        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .moltenVK })?.status, .missing)
    }

    func testIncompleteProfileDoesNotMakeGameProfileReady() async {
        let service = makeService()
        var profile = configuredProfile()
        profile.workingDirectoryBookmarkData = nil

        let summary = await service.loadSummary(profiles: [profile])

        XCTAssertEqual(summary.dependencies.first(where: { $0.kind == .gameProfile })?.status, .missing)
    }

    func testDependencyOrderIsDeterministic() async {
        let service = makeService()

        let summary = await service.loadSummary(profiles: [configuredProfile()])

        XCTAssertEqual(summary.dependencies.map(\.kind), [.rosetta, .wine, .dxvk, .moltenVK, .gameProfile])
    }

    func testOverallStatusIsDerivedFromDependencies() async {
        let service = RealDependencyDiagnosticService(
            rosettaProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .rosetta, status: .ready)),
            wineProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .wine, status: .unknown)),
            dxvkProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .dxvk, status: .notRequired)),
            moltenVKProvider: FakeRuntimeDiagnosticProvider(
                dependency: dependency(kind: .moltenVK, status: .notRequired)
            )
        )

        let summary = await service.loadSummary(profiles: [configuredProfile()])

        XCTAssertEqual(summary.overallStatus, .unknown)
    }

    private func makeService() -> RealDependencyDiagnosticService {
        RealDependencyDiagnosticService(
            rosettaProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .rosetta, status: .ready)),
            wineProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .wine, status: .ready)),
            dxvkProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .dxvk, status: .missing)),
            moltenVKProvider: FakeRuntimeDiagnosticProvider(dependency: dependency(kind: .moltenVK, status: .missing))
        )
    }

    private func dependency(
        kind: RuntimeDependencyKind,
        status: RuntimeDependencyStatus,
        version: String? = nil
    ) -> RuntimeDependency {
        RuntimeDependency(
            displayName: displayName(for: kind),
            kind: kind,
            status: status,
            version: version,
            installPath: nil,
            userFacingDescription: "Test dependency",
            missingReason: status == .missing ? "Missing" : nil,
            suggestedAction: nil,
            setupGuide: nil
        )
    }

    private func displayName(for kind: RuntimeDependencyKind) -> String {
        switch kind {
        case .rosetta:
            return "Rosetta"
        case .wine:
            return "Wine"
        case .dxvk:
            return "DXVK"
        case .moltenVK:
            return "MoltenVK"
        case .gameProfile:
            return "Game Profile"
        }
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
}

private struct FakeRuntimeDiagnosticProvider: RuntimeDiagnosticProviding {
    let dependency: RuntimeDependency

    func diagnose() async -> RuntimeDependency {
        dependency
    }
}
