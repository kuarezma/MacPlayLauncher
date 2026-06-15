import Foundation

enum MacPlayError: LocalizedError, Equatable, Sendable {
    case profileNotFound
    case invalidPath
    case bookmarkUnavailable
    case bookmarkStale
    case executableOutsideGameFolder
    case unsupportedSchemaVersion(Int)

    var errorDescription: String? {
        switch self {
        case .profileNotFound:
            return String(localized: "error.profileNotFound")
        case .invalidPath:
            return String(localized: "error.invalidPath")
        case .bookmarkUnavailable:
            return String(localized: "error.bookmarkUnavailable")
        case .bookmarkStale:
            return String(localized: "error.bookmarkStale")
        case .executableOutsideGameFolder:
            return String(localized: "error.executableOutsideGameFolder")
        case .unsupportedSchemaVersion(let version):
            return String(format: String(localized: "error.unsupportedSchemaVersion"), version)
        }
    }
}
