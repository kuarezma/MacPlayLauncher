import XCTest
@testable import MacPlayLauncher

final class MigrationManagerTests: XCTestCase {
    func testSchemaVersionOneNoOpMigration() throws {
        let profile = GameProfile.sampleCossacks3
        let migrated = try MigrationManager().migrate(profile)

        XCTAssertEqual(migrated, profile)
    }
}

