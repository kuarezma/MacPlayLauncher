import Foundation

protocol GameProfileManaging: Sendable {
    func loadProfiles() throws -> [GameProfile]
    func saveProfile(_ profile: GameProfile) throws
    func deleteProfile(id: String) throws
}

struct GameProfileManager: GameProfileManaging {
    private let store: JSONStore<GameProfile>

    init(store: JSONStore<GameProfile>) {
        self.store = store
    }

    func loadProfiles() throws -> [GameProfile] {
        try store.loadAll().sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }

    func saveProfile(_ profile: GameProfile) throws {
        try store.save(profile, named: profile.id)
    }

    func deleteProfile(id: String) throws {
        try store.delete(named: id)
    }
}

