import Foundation

enum LocalizedFallback {
    static func text(_ key: StaticString, fallback: String) -> String {
        String(
            localized: key,
            defaultValue: String.LocalizationValue(fallback)
        )
    }
}
