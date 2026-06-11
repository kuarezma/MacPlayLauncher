import Foundation

enum PathSanitizer {
    static func fileName(_ value: String) -> String {
        let allowed = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_")
        let sanitized = value.map { allowed.contains($0) ? $0 : "-" }
        let result = String(sanitized).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return result.isEmpty ? "item" : result
    }
}
