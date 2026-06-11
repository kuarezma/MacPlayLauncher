import XCTest
@testable import MacPlayLauncher

final class RuntimeManifestTests: XCTestCase {
    func testRuntimeManifestEncodeDecode() throws {
        let manifests = [
            RuntimeManifest.sampleWine,
            RuntimeManifest.sampleDXVK,
            RuntimeManifest.sampleMoltenVK
        ]

        for manifest in manifests {
            let data = try JSONEncoder.testEncoder.encode(manifest)
            let decoded = try JSONDecoder.testDecoder.decode(RuntimeManifest.self, from: data)
            XCTAssertEqual(decoded, manifest)
        }
    }
}

