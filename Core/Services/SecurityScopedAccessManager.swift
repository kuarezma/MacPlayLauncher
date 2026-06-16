import Foundation

protocol SecurityScopedAccessManaging: Sendable {
    func withAccess<T>(to urls: [URL], perform operation: () throws -> T) throws -> T
}

struct SecurityScopedAccessManager: SecurityScopedAccessManaging {
    func withAccess<T>(to urls: [URL], perform operation: () throws -> T) throws -> T {
        var accessedURLs: [URL] = []

        defer {
            for url in accessedURLs {
                url.stopAccessingSecurityScopedResource()
            }
        }

        for url in urls {
            guard url.startAccessingSecurityScopedResource() else {
                throw MacPlayError.securityScopedAccessDenied
            }
            accessedURLs.append(url)
        }

        return try operation()
    }
}
