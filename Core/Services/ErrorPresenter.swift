import Foundation

enum ErrorPresenter {
    static func message(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription {
            return description
        }

        return String(localized: "error.generic")
    }
}
