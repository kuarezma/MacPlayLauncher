import Foundation

struct BundledGameProfileLoader: Sendable {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadCossacks3Profile() throws -> GameProfile {
        let resourceURL = try cossacks3ProfileURL()
        let data = try Data(contentsOf: resourceURL)
        return try Self.makeDecoder().decode(GameProfile.self, from: data)
    }

    private func cossacks3ProfileURL() throws -> URL {
        let candidates = [
            bundle.url(forResource: "cossacks3.profile", withExtension: "json", subdirectory: "Profiles"),
            bundle.url(forResource: "cossacks3.profile", withExtension: "json", subdirectory: "Resources/Profiles"),
            bundle.url(forResource: "cossacks3.profile", withExtension: "json")
        ]

        guard let url = candidates.compactMap({ $0 }).first else {
            throw MacPlayError.profileNotFound
        }

        return url
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
