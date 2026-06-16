import XCTest
@testable import MacPlayLauncher

final class DiagnosticModeTests: XCTestCase {
    func testProductionPolicyDefaultsToStaticOnly() {
        let policy = DiagnosticActivationPolicy.production

        XCTAssertEqual(policy.defaultMode, .staticOnly)
        XCTAssertTrue(policy.allowsRealDiagnostics)
        XCTAssertTrue(policy.requiresExplicitUserAction)
    }

    func testInternalPolicyAllowsRealReadOnly() {
        let policy = DiagnosticActivationPolicy.internalRealReadOnly

        XCTAssertEqual(policy.defaultMode, .realReadOnly)
        XCTAssertTrue(policy.allowsRealDiagnostics)
        XCTAssertFalse(policy.requiresExplicitUserAction)
    }

    func testDiagnosticModeCasesAreStable() {
        XCTAssertEqual(DiagnosticMode.staticOnly.rawValue, "staticOnly")
        XCTAssertEqual(DiagnosticMode.realReadOnly.rawValue, "realReadOnly")
    }

    func testDiagnosticsSourceCasesAreStable() {
        XCTAssertEqual(DiagnosticsSource.staticPreparation.rawValue, "staticPreparation")
        XCTAssertEqual(DiagnosticsSource.realSystemCheck.rawValue, "realSystemCheck")
    }
}
