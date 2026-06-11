import XCTest
@testable import MacPlayLauncher

final class DependencyTests: XCTestCase {
    func testDependencyEncodeDecode() throws {
        let dependency = Dependency(
            id: "d3dx9",
            displayName: "DirectX 9 Helper Libraries",
            required: true,
            installed: false,
            installOrder: 3,
            dependsOn: []
        )

        let data = try JSONEncoder.testEncoder.encode(dependency)
        let decoded = try JSONDecoder.testDecoder.decode(Dependency.self, from: data)

        XCTAssertEqual(decoded, dependency)
    }
}

