import XCTest
@testable import MacPlayLauncher

final class PerformanceModeTests: XCTestCase {
    func testRecommendationUsesCoolModeOnBattery() {
        XCTAssertEqual(
            PerformanceMode.recommended(isPortableMac: true, isOnBattery: true, memoryGB: 16),
            .coolBatterySafe
        )
    }

    func testRecommendationUsesCoolModeForEightGBMemory() {
        XCTAssertEqual(
            PerformanceMode.recommended(isPortableMac: false, isOnBattery: false, memoryGB: 8),
            .coolBatterySafe
        )
    }

    func testRecommendationUsesBalancedForPortableMacOnAC() {
        XCTAssertEqual(
            PerformanceMode.recommended(isPortableMac: true, isOnBattery: false, memoryGB: 16),
            .balanced
        )
    }
}

