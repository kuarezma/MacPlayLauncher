@testable import MacPlayLauncher
import XCTest

final class CossacksOptimizationAdvisorTests: XCTestCase {
    func testHasDLLOverrideConfiguredWhenOpenGLProxyAndFallbackOverridesExist() {
        let profile = makeProfile(
            environment: ["WINEDLLOVERRIDES": "d3d9,d3d11,dxgi=b"]
        )

        XCTAssertTrue(CossacksOptimizationAdvisor.hasDLLOverrideConfigured(profile))
    }

    func testHasDLLOverrideNotConfiguredWhenOverrideIsMissing() {
        let profile = makeProfile(environment: [:])

        XCTAssertFalse(CossacksOptimizationAdvisor.hasDLLOverrideConfigured(profile))
    }

    func testStatusItemsExposeReadyLocalWineProfile() throws {
        let profile = makeProfile(
            environment: ["WINEDLLOVERRIDES": "d3d9,d3d11,dxgi=b"],
            requiresWineSteam: false,
            runtime: .systemWineFallback,
            knownIssues: ["Ekran çözünürlüğü 1280×800 olarak ayarlanmalıdır."]
        )

        let items = CossacksOptimizationAdvisor.statusItems(for: profile)

        XCTAssertEqual(items.count, 4)
        XCTAssertEqual(try XCTUnwrap(items.first { $0.id == "dll" }).state, .ready)
        XCTAssertEqual(try XCTUnwrap(items.first { $0.id == "steam" }).state, .ready)
        XCTAssertEqual(try XCTUnwrap(items.first { $0.id == "runtime" }).state, .ready)
        XCTAssertEqual(try XCTUnwrap(items.first { $0.id == "resolution" }).state, .ready)
    }

    func testStatusItemsFlagCrossOverRuntimeAndResolutionNote() throws {
        let profile = makeProfile(
            environment: ["WINEDLLOVERRIDES": "d3d9,d3d11,dxgi=b"],
            requiresWineSteam: true,
            runtime: .crossOver,
            crossOverBottleName: nil,
            knownIssues: []
        )

        let items = CossacksOptimizationAdvisor.statusItems(for: profile)

        XCTAssertEqual(try XCTUnwrap(items.first { $0.id == "runtime" }).state, .needsAttention)
        XCTAssertEqual(try XCTUnwrap(items.first { $0.id == "resolution" }).state, .needsAttention)
    }

    private func makeProfile(
        environment: [String: String],
        requiresWineSteam: Bool? = false,
        runtime: RuntimeKind = .systemWineFallback,
        crossOverBottleName: String? = "Cossacks3",
        knownIssues: [String] = ["Ekran çözünürlüğü 1280×800 olarak ayarlanmalıdır."]
    ) -> GameProfile {
        GameProfile(
            schemaVersion: GameProfile.currentSchemaVersion,
            id: "cossacks3",
            displayName: "Cossacks 3",
            executablePath: nil,
            workingDirectory: nil,
            prefixPath: "Prefixes/cossacks3",
            executableBookmarkData: nil,
            workingDirectoryBookmarkData: nil,
            runtime: runtime,
            crossOverBottleName: crossOverBottleName,
            performanceMode: .balanced,
            wineArch: .win64,
            windowsVersion: .win10,
            dependencies: [],
            environment: environment,
            launchArguments: [],
            knownIssues: knownIssues,
            requiresWineSteam: requiresWineSteam,
            lastPlayedAt: nil,
            totalPlayTimeMinutes: 0,
            launchCount: 0
        )
    }
}
