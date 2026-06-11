import Foundation

struct LaunchSession: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var profileID: String
    var startedAt: Date
    var endedAt: Date?
    var exitCode: Int?
    var summary: String?

    static let sample = LaunchSession(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
        profileID: "cossacks3",
        startedAt: Date(timeIntervalSince1970: 1_800_000_000),
        endedAt: nil,
        exitCode: nil,
        summary: nil
    )
}

