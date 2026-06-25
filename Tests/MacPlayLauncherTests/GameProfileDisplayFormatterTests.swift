@testable import MacPlayLauncher
import XCTest

final class GameProfileDisplayFormatterTests: XCTestCase {
    func testRuntimeAndPerformanceLabelsAreUserFacing() {
        XCTAssertEqual(
            GameProfileDisplayFormatter.runtimeTitle(for: .wineDXVKMoltenVK),
            "Wine + DXVK + MoltenVK"
        )
        XCTAssertEqual(
            GameProfileDisplayFormatter.performanceTitle(for: .balanced),
            "Dengeli"
        )
        XCTAssertEqual(
            GameProfileDisplayFormatter.windowsVersionTitle(for: .win10),
            "Windows 10"
        )
    }

    func testSampleProfileIsNotUserConfigured() {
        let profile = GameProfile.sampleCossacks3

        XCTAssertFalse(GameProfileDisplayFormatter.isUserConfigured(profile))
        XCTAssertEqual(
            GameProfileDisplayFormatter.profileKindTitle(for: profile),
            "Örnek profil"
        )
        XCTAssertEqual(
            GameProfileDisplayFormatter.setupNote(for: profile),
            "Bu örnek profil çalıştırılamaz; kendi oyun klasörünüzü ekleyin."
        )
    }

    func testUserProfileIsDetectedFromPathsAndBookmarks() {
        let profile = GameProfile(
            schemaVersion: GameProfile.currentSchemaVersion,
            id: "user-game",
            displayName: "User Game",
            executablePath: "/Games/Cossacks/Cossacks.exe",
            workingDirectory: "/Games/Cossacks",
            prefixPath: "Prefixes/user-game",
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

        XCTAssertTrue(GameProfileDisplayFormatter.isUserConfigured(profile))
        XCTAssertEqual(
            GameProfileDisplayFormatter.profileKindTitle(for: profile),
            "Kullanıcı profili"
        )
        XCTAssertNil(GameProfileDisplayFormatter.setupNote(for: profile))
    }
}
