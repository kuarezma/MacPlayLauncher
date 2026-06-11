import XCTest
@testable import MacPlayLauncher

final class JSONStoreTests: XCTestCase {
    func testReadWriteDelete() throws {
        let directory = try temporaryDirectory()
        let store = JSONStore<GameProfile>(directoryURL: directory, fileSystem: LocalFileSystem())
        let profile = GameProfile.sampleCossacks3

        try store.save(profile, named: profile.id)

        XCTAssertEqual(try store.load(named: profile.id), profile)
        XCTAssertEqual(try store.loadAll(), [profile])

        try store.delete(named: profile.id)

        XCTAssertTrue(try store.loadAll().isEmpty)
    }
}

