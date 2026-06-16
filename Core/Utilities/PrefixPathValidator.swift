import Foundation

enum PrefixPathValidator {
    static func validate(profile: GameProfile) throws {
        let path = profile.prefixPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard path.hasPrefix("Prefixes/") else {
            throw MacPlayError.invalidPrefixPath
        }

        guard !path.contains("..") else {
            throw MacPlayError.invalidPrefixPath
        }

        let suffix = String(path.dropFirst("Prefixes/".count))
        guard !suffix.isEmpty, suffix == profile.id, !suffix.contains("/") else {
            throw MacPlayError.invalidPrefixPath
        }
    }

    static func validateResolved(_ url: URL, prefixesRoot: URL) throws {
        let resolved = url.standardizedFileURL.resolvingSymlinksInPath()
        let root = prefixesRoot.standardizedFileURL.resolvingSymlinksInPath()
        let rootComponents = root.pathComponents
        let resolvedComponents = resolved.pathComponents

        guard resolvedComponents.count > rootComponents.count,
              Array(resolvedComponents.prefix(rootComponents.count)) == rootComponents else {
            throw MacPlayError.invalidPrefixPath
        }
    }
}
