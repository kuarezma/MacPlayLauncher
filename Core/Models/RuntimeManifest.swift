struct RuntimeManifest: Codable, Equatable, Identifiable, Sendable {
    let schemaVersion: Int
    let id: String
    var displayName: String
    var version: String
    var architecture: String
    var installPath: String
    var binaryPath: String?
    var sha256: String?
    var supports: [String]
    var licenseType: String?
    var codesignRequired: Bool

    static let sampleWine = RuntimeManifest(
        schemaVersion: SchemaVersion.current,
        id: "wine",
        displayName: "Wine Runtime",
        version: "placeholder",
        architecture: "x86_64",
        installPath: "Runtimes/wine",
        binaryPath: "Runtimes/wine/bin/wine64",
        sha256: nil,
        supports: ["win64"],
        licenseType: "LGPL-2.1",
        codesignRequired: true
    )

    static let sampleDXVK = RuntimeManifest(
        schemaVersion: SchemaVersion.current,
        id: "dxvk",
        displayName: "DXVK",
        version: "placeholder",
        architecture: "win32-win64",
        installPath: "Runtimes/dxvk",
        binaryPath: nil,
        sha256: nil,
        supports: ["d3d9", "d3d10", "d3d11"],
        licenseType: "zlib",
        codesignRequired: false
    )

    static let sampleMoltenVK = RuntimeManifest(
        schemaVersion: SchemaVersion.current,
        id: "moltenvk",
        displayName: "MoltenVK",
        version: "placeholder",
        architecture: "arm64",
        installPath: "Runtimes/moltenvk",
        binaryPath: nil,
        sha256: nil,
        supports: ["vulkan-to-metal"],
        licenseType: "Apache-2.0",
        codesignRequired: true
    )
}

