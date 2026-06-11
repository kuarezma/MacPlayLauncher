import XCTest
@testable import MacPlayLauncher

final class GameProfileTests: XCTestCase {
    func testSampleCossacks3EncodeDecode() throws {
        let profile = GameProfile.sampleCossacks3
        let data = try JSONEncoder.testEncoder.encode(profile)
        let decoded = try JSONDecoder.testDecoder.decode(GameProfile.self, from: data)

        XCTAssertEqual(decoded, profile)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.wineArch, .win64)
        XCTAssertEqual(decoded.windowsVersion, .win10)
        XCTAssertEqual(decoded.runtime, .wineDXVKMoltenVK)
        XCTAssertEqual(decoded.performanceMode, .balanced)
    }
}

