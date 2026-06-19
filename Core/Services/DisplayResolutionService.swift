import Foundation

protocol DisplayResolutionServicing: Sendable {
    func setGameResolution()
    func restoreResolution()
}

// @unchecked Sendable — setGameResolution/restoreResolution çağrıları sıralı, race yok
final class DisplayResolutionService: DisplayResolutionServicing, @unchecked Sendable {
    private static let displayplacerPath = "/opt/homebrew/bin/displayplacer"
    private static let gameWidth = 1280
    private static let gameHeight = 800

    private var savedConfig: String?

    func setGameResolution() {
        guard let (id, currentMode) = mainDisplayConfig() else { return }
        savedConfig = "id:\(id) \(currentMode)"
        let gameMode = replaceResolution(in: currentMode, width: Self.gameWidth, height: Self.gameHeight)
        runDisplayplacer("id:\(id) \(gameMode)")
    }

    func restoreResolution() {
        guard let config = savedConfig else { return }
        runDisplayplacer(config)
        savedConfig = nil
    }

    // MARK: - Private

    private func replaceResolution(in mode: String, width: Int, height: Int) -> String {
        let pattern = #"res:\d+x\d+"#
        guard let range = mode.range(of: pattern, options: .regularExpression) else { return mode }
        return mode.replacingCharacters(in: range, with: "res:\(width)x\(height)")
    }

    private func mainDisplayConfig() -> (id: String, mode: String)? {
        guard let output = runAndCapture(["list"]) else { return nil }
        var id: String?
        var mode: String?
        for line in output.components(separatedBy: "\n") {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("Persistent screen id:"), let v = t.components(separatedBy: ": ").last {
                id = v.trimmingCharacters(in: .whitespaces)
            }
            if t.contains("<-- current mode") {
                // örn: "  mode 6: res:1470x956 hz:60 color_depth:8 scaling:on <-- current mode"
                if let colon = t.firstIndex(of: ":"),
                   let start = t.index(colon, offsetBy: 2, limitedBy: t.endIndex) {
                    mode = String(t[start...])
                        .replacingOccurrences(of: "<-- current mode", with: "")
                        .trimmingCharacters(in: .whitespaces)
                }
            }
        }
        guard let displayId = id, let currentMode = mode else { return nil }
        return (displayId, currentMode)
    }

    private func runAndCapture(_ args: [String]) -> String? {
        guard FileManager.default.fileExists(atPath: Self.displayplacerPath) else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.displayplacerPath)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
    }

    private func runDisplayplacer(_ config: String) {
        guard FileManager.default.fileExists(atPath: Self.displayplacerPath) else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Self.displayplacerPath)
        process.arguments = [config]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
    }
}
