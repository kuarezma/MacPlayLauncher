import XCTest
@testable import MacPlayLauncher

final class LaunchSessionTests: XCTestCase {
    func testLaunchSessionEncodeDecode() throws {
        let session = LaunchSession.sample
        let data = try JSONEncoder.testEncoder.encode(session)
        let decoded = try JSONDecoder.testDecoder.decode(LaunchSession.self, from: data)

        XCTAssertEqual(decoded, session)
    }
}

