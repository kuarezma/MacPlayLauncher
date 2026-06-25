import Foundation

struct GameProfile: Codable, Equatable, Identifiable, Sendable {
    static let currentSchemaVersion = SchemaVersion.current

    let schemaVersion: Int
    let id: String
    var displayName: String
    var executablePath: String?
    var workingDirectory: String?
    var prefixPath: String
    var executableBookmarkData: Data?
    var workingDirectoryBookmarkData: Data?
    var runtime: RuntimeKind
    var crossOverBottleName: String?
    var performanceMode: PerformanceMode
    var wineArch: WineArchitecture
    var windowsVersion: WindowsVersion
    var dependencies: [Dependency]
    var environment: [String: String]
    var launchArguments: [String]
    var knownIssues: [String]
    var requiresWineSteam: Bool?
    var lastPlayedAt: Date?
    var totalPlayTimeMinutes: Int
    var launchCount: Int

    static let sampleCossacks3 = GameProfile(
        schemaVersion: currentSchemaVersion,
        id: "cossacks3",
        displayName: "Cossacks 3",
        executablePath: nil,
        workingDirectory: nil,
        prefixPath: "Prefixes/cossacks3",
        executableBookmarkData: nil,
        workingDirectoryBookmarkData: nil,
        runtime: .systemWineFallback,
        crossOverBottleName: nil,
        performanceMode: .balanced,
        wineArch: .win64,
        windowsVersion: .win10,
        dependencies: [
            Dependency(
                id: "corefonts",
                displayName: "Core Fonts",
                required: false,
                installed: false,
                installOrder: 1,
                dependsOn: []
            ),
            Dependency(
                id: "vcrun2015",
                displayName: "Microsoft Visual C++ 2015 Runtime",
                required: true,
                installed: false,
                installOrder: 2,
                dependsOn: []
            ),
            Dependency(
                id: "d3dx9",
                displayName: "DirectX 9 Helper Libraries",
                required: true,
                installed: false,
                installOrder: 3,
                dependsOn: []
            ),
            Dependency(
                id: "xact",
                displayName: "XAudio/XACT Runtime",
                required: false,
                installed: false,
                installOrder: 4,
                dependsOn: ["vcrun2015"]
            )
        ],
        environment: [
            "WINEDLLOVERRIDES": "d3d9,d3d11,dxgi=b",
            "WINEESYNC": "0"
        ],
        launchArguments: [],
        knownIssues: [
            "İlk açılışta görünmez onay kutusu çıkarsa oyun penceresine tıklayıp Return tuşuna basın.",
            "Bu profil CrossOver gerektirmez; yerel WineCX motorunu kullanır."
        ],
        requiresWineSteam: false,
        lastPlayedAt: nil,
        totalPlayTimeMinutes: 0,
        launchCount: 0
    )
}
