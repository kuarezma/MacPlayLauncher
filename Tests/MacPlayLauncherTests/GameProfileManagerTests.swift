@testable import MacPlayLauncher
import XCTest

final class GameProfileManagerTests: XCTestCase {
    func testSaveLoadDeleteProfile() throws {
        let directory = try temporaryDirectory()
        let store = JSONStore<GameProfile>(directoryURL: directory, fileSystem: LocalFileSystem())
        let manager = GameProfileManager(store: store)
        let profile = GameProfile.sampleCossacks3

        try manager.saveProfile(profile)

        XCTAssertEqual(try manager.loadProfiles(), [profile])

        try manager.deleteProfile(id: profile.id)

        XCTAssertTrue(try manager.loadProfiles().isEmpty)
    }
}
