import Foundation

struct DiagnosticReport: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var createdAt: Date
    var appVersion: String
    var profileCount: Int
    var notes: [String]

    static let sample = DiagnosticReport(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
        createdAt: Date(timeIntervalSince1970: 1_800_000_000),
        appVersion: "0.1.0",
        profileCount: 1,
        notes: ["Sprint 1 placeholder diagnostics only."]
    )
}
