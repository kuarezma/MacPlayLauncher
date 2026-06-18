import Foundation

enum MacPlayError: LocalizedError, Equatable, Sendable {
    case profileNotFound
    case invalidPath
    case bookmarkUnavailable
    case bookmarkStale
    case executableOutsideGameFolder
    case invalidPrefixPath
    case prefixDirectoryMissing
    case wineNotFound
    case crossOverNotFound
    case securityScopedAccessDenied
    case launchPreparationFailed
    case launchFailed(String)
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
        case .invalidPrefixPath:
            return String(localized: "error.invalidPrefixPath")
        case .prefixDirectoryMissing:
            return String(localized: "error.prefixDirectoryMissing")
        case .wineNotFound:
            return String(localized: "error.wineNotFound")
        case .crossOverNotFound:
            return String(localized: "error.crossOverNotFound")
        case .securityScopedAccessDenied:
            return String(localized: "error.securityScopedAccessDenied")
        case .launchPreparationFailed:
            return String(localized: "error.launchPreparationFailed")
        case .launchFailed(let message):
            return message
        case .unsupportedSchemaVersion(let version):
            return String(format: String(localized: "error.unsupportedSchemaVersion"), version)
        }
    }
}
