@testable import MacPlayLauncher
import XCTest

final class GameProfileTests: XCTestCase {
    func testBundledCossacks3ProfileDecodes() throws {
        #if SWIFT_PACKAGE
        let profile = try BundledGameProfileLoader(bundle: .module).loadCossacks3Profile()
        #else
        // Bundle.module is SPM-only. In xcodebuild, load directly from the source tree
        // using #file so this works on any machine without bundle resource path ambiguity.
        let jsonURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/Profiles/cossacks3.profile.json")
        let data = try Data(contentsOf: jsonURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let profile = try decoder.decode(GameProfile.self, from: data)
        #endif

        XCTAssertEqual(profile.id, "cossacks3")
        XCTAssertEqual(profile.schemaVersion, 1)
        XCTAssertEqual(profile.wineArch, .win64)
        XCTAssertEqual(profile.windowsVersion, .win10)
        XCTAssertEqual(profile.runtime, .crossOver)
        XCTAssertEqual(profile.crossOverBottleName, "Cossacks3")
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
        XCTAssertEqual(decoded.runtime, .crossOver)
        XCTAssertEqual(decoded.crossOverBottleName, "Cossacks3")
        XCTAssertEqual(decoded.performanceMode, .balanced)
    }
}
