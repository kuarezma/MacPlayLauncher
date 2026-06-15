import XCTest
@testable import MacPlayLauncher

final class GameProfileTests: XCTestCase {
    func testBundledCossacks3ProfileDecodes() throws {
        let bundle = try XCTUnwrap(Bundle(identifier: "ugur.MacPlayLauncher"))
        let profile = try BundledGameProfileLoader(bundle: bundle).loadCossacks3Profile()

        XCTAssertEqual(profile.id, "cossacks3")
        XCTAssertEqual(profile.schemaVersion, 1)
        XCTAssertEqual(profile.wineArch, .win64)
        XCTAssertEqual(profile.windowsVersion, .win10)
        XCTAssertEqual(profile.runtime, .wineDXVKMoltenVK)
        XCTAssertEqual(profile.performanceMode, .balanced)
    }

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
