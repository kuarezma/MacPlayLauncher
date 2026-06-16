import Foundation

struct PrefixDirectoryState: Equatable, Sendable {
    enum Availability: Equatable, Sendable {
        case missing
        case exists
    }

    let profileID: String
    let displayName: String
    let relativePath: String
    let absolutePath: String
    let availability: Availability
}
