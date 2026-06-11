struct MigrationManager: Sendable {
    func migrate(_ profile: GameProfile) throws -> GameProfile {
        guard profile.schemaVersion <= SchemaVersion.current else {
            throw MacPlayError.unsupportedSchemaVersion(profile.schemaVersion)
        }

        return profile
    }
}

