import Foundation

enum PathContainmentValidator {
    static func validateExecutable(_ executableURL: URL, isInside folderURL: URL) throws {
        guard executableURL.pathExtension.lowercased() == "exe" else {
            throw MacPlayError.invalidPath
        }

        let folderComponents = normalizedComponents(for: folderURL)
        let executableComponents = normalizedComponents(for: executableURL)

        guard executableComponents.count > folderComponents.count,
              Array(executableComponents.prefix(folderComponents.count)) == folderComponents else {
            throw MacPlayError.executableOutsideGameFolder
        }
    }

    private static func normalizedComponents(for url: URL) -> [String] {
        url.standardizedFileURL
            .resolvingSymlinksInPath()
            .pathComponents
    }
}
