@testable import MacPlayLauncher
import XCTest

final class DiagnosticReportTests: XCTestCase {
    func testDiagnosticReportEncodeDecode() throws {
        let report = DiagnosticReport.sample
        let data = try JSONEncoder.testEncoder.encode(report)
        let decoded = try JSONDecoder.testDecoder.decode(DiagnosticReport.self, from: data)

        XCTAssertEqual(decoded, report)
    }
}
