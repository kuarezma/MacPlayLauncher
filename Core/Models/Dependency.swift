struct Dependency: Codable, Equatable, Identifiable, Sendable {
    let id: String
    var displayName: String
    var required: Bool
    var installed: Bool
    var installOrder: Int
    var dependsOn: [String]
}
