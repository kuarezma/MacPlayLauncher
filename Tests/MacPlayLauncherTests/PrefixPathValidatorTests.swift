import Foundation
import XCTest
@testable import MacPlayLauncher

final class PrefixPathValidatorTests: XCTestCase {
    func testValidProfilePrefixPathPasses() throws {
        try PrefixPathValidator.validate(profile: makeProfile(prefixPath: "Prefixes/cossacks3", id: "cossacks3"))
    }

    func testRejectsPrefixOutsidePrefixesRoot() {
        XCTAssertThrowsError(
            try PrefixPathValidator.validate(profile: makeProfile(prefixPath: "Runtime/cossacks3", id: "cossacks3"))
        ) { error in
            XCTAssertEqual(error as? MacPlayError, .invalidPrefixPath)
        }
    }

    func testRejectsNestedPrefixPath() {
        XCTAssertThrowsError(
            try PrefixPathValidator.validate(profile: makeProfile(prefixPath: "Prefixes/cossacks3/nested", id: "cossacks3"))
        ) { error in
            XCTAssertEqual(error as? MacPlayError, .invalidPrefixPath)
        }
    }

    private func makeProfile(prefixPath: String, id: String) -> GameProfile {
        GameProfile(
            schemaVersion: GameProfile.currentSchemaVersion,
            id: id,
            displayName: "Cossacks 3",
            executablePath: nil,
            workingDirectory: nil,
            prefixPath: prefixPath,
            executableBookmarkData: nil,
            workingDirectoryBookmarkData: nil,
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
