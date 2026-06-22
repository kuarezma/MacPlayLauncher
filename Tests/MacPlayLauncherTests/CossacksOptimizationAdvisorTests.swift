@testable import MacPlayLauncher
import XCTest

final class CossacksOptimizationAdvisorTests: XCTestCase {
    func testHasMinimapFixEnabledWhenOpenGLProxyAndFallbackOverridesExist() {
        let profile = makeProfile(
            environment: ["WINEDLLOVERRIDES": "opengl32=n,b;d3d9,d3d11,dxgi=b"]
        )

        XCTAssertTrue(CossacksOptimizationAdvisor.hasMinimapFixEnabled(profile))
    }

    func testHasMinimapFixDisabledWhenOverrideIsMissing() {
        let profile = makeProfile(environment: [:])

        XCTAssertFalse(CossacksOptimizationAdvisor.hasMinimapFixEnabled(profile))
    }

    func testStatusItemsExposeReadyCrossOverAndSteamProfile() throws {
        let profile = makeProfile(
            environment: ["WINEDLLOVERRIDES": "opengl32=n,b;d3d9,d3d11,dxgi=b"],
            requiresWineSteam: true,
            crossOverBottleName: "Cossacks3",
            knownIssues: ["Ekran çözünürlüğü 1280×800 olarak ayarlanmalıdır."]
        )

        let items = CossacksOptimizationAdvisor.statusItems(for: profile)

        XCTAssertEqual(items.count, 4)
        XCTAssertEqual(try XCTUnwrap(items.first { $0.id == "minimap" }).state, .ready)
        XCTAssertEqual(try XCTUnwrap(items.first { $0.id == "steam" }).state, .ready)
        XCTAssertEqual(try XCTUnwrap(items.first { $0.id == "crossover" }).state, .ready)
        XCTAssertEqual(try XCTUnwrap(items.first { $0.id == "resolution" }).state, .ready)
    }

    func testStatusItemsFlagMissingBottleAndResolutionNote() throws {
        var profile = makeProfile(
            environment: ["WINEDLLOVERRIDES": "opengl32=n,b;d3d9,d3d11,dxgi=b"],
            requiresWineSteam: true,
            crossOverBottleName: nil,
            knownIssues: []
        )
        profile.runtime = .crossOver

        let items = CossacksOptimizationAdvisor.statusItems(for: profile)

        XCTAssertEqual(try XCTUnwrap(items.first { $0.id == "crossover" }).state, .needsAttention)
        XCTAssertEqual(try XCTUnwrap(items.first { $0.id == "resolution" }).state, .needsAttention)
    }

    private func makeProfile(
        environment: [String: String],
        requiresWineSteam: Bool? = true,
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
            runtime: .crossOver,
            crossOverBottleName: crossOverBottleName,
            performanceMode: .balanced,
            wineArch: .win64,
            windowsVersion: .win10,
            dependencies: [],
            environment: environment,
            launchArguments: ["C:\\Cossacks3\\steamclient_loader_x86.exe"],
            knownIssues: knownIssues,
            requiresWineSteam: requiresWineSteam,
            lastPlayedAt: nil,
            totalPlayTimeMinutes: 0,
            launchCount: 0
        )
    }
}
