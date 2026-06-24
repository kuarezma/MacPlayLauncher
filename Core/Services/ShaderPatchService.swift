import Foundation

struct UnitVertexShaderRepairResult: Equatable, Sendable {
    let backupSourceURL: URL?
    let restoredFileNames: [String]

    var restoredCount: Int { restoredFileNames.count }
}

struct ShaderPatchService: Sendable {
    let gameShaderPath: URL

    private var backupPath: URL {
        gameShaderPath.deletingLastPathComponent().appending(path: "obj_yedek", directoryHint: .isDirectory)
    }

    func isAlreadyPatched() -> Bool {
        let probes = ["hf.pvl.smx3.frag", "env.smx3.id3.frag", "unit.smx3.id8.frag"]
        return probes.allSatisfy { name in
            let url = gameShaderPath.appending(path: name, directoryHint: .notDirectory)
            guard let content = try? String(contentsOf: url, encoding: .utf8) else { return false }
            return content.contains("gl_FragColor = vec4(tex0.rgb, 1.0);")
        }
    }

    func createBackupIfNeeded() throws {
        guard !FileManager.default.fileExists(atPath: backupPath.path) else { return }
        try FileManager.default.copyItem(at: gameShaderPath, to: backupPath)
    }

    @discardableResult
    func createTimestampedBackup(prefix: String = "obj_unit_render_backup") throws -> URL {
        let parent = gameShaderPath.deletingLastPathComponent()
        var candidate = parent.appending(
            path: "\(prefix)_\(Self.timestamp())",
            directoryHint: .isDirectory
        )
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = parent.appending(
                path: "\(prefix)_\(Self.timestamp())_\(suffix)",
                directoryHint: .isDirectory
            )
            suffix += 1
        }
        try FileManager.default.copyItem(at: gameShaderPath, to: candidate)
        return candidate
    }

    func needsUnitVertexShaderRepair() throws -> Bool {
        guard let source = bestUnitVertexShaderBackupSource() else { return false }
        return try unitVertexShaderURLs(in: source).contains { sourceURL in
            let targetURL = gameShaderPath.appending(
                path: sourceURL.lastPathComponent,
                directoryHint: .notDirectory
            )
            return !FileManager.default.contentsEqual(atPath: sourceURL.path, andPath: targetURL.path)
        }
    }

    @discardableResult
    func repairUnitVertexShadersFromBestBackupIfAvailable() throws -> UnitVertexShaderRepairResult {
        guard let source = bestUnitVertexShaderBackupSource() else {
            return UnitVertexShaderRepairResult(backupSourceURL: nil, restoredFileNames: [])
        }
        var restoredFileNames: [String] = []
        for sourceURL in try unitVertexShaderURLs(in: source) {
            let targetURL = gameShaderPath.appending(
                path: sourceURL.lastPathComponent,
                directoryHint: .notDirectory
            )
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: targetURL)
            restoredFileNames.append(sourceURL.lastPathComponent)
        }
        return UnitVertexShaderRepairResult(
            backupSourceURL: source,
            restoredFileNames: restoredFileNames.sorted()
        )
    }

    func apply() throws {
        try applyUnitFragFix()
        try applyFXFix()
        try applyMinimalFragFix()
    }

    // MARK: - Unit Fragment Fix

    private func applyUnitFragFix() throws {
        let unitFrag = """
        uniform sampler2D texUnit0;
        uniform vec4 custColor;
        void main()
        {
           vec4 tex0 = texture2D(texUnit0, gl_TexCoord[0].xy);
           float team = step(0.15, max(custColor.r, max(custColor.g, custColor.b)));
           tex0.rgb = mix(tex0.rgb, custColor.rgb*tex0.rgb, tex0.a*custColor.a*team);
           gl_FragColor = vec4(tex0.rgb, 1.0);
        }
        """
        for name in ["unit.smx3.id8.frag", "unit.smx9.id8.frag"] {
            let url = gameShaderPath.appending(path: name, directoryHint: .notDirectory)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            try unitFrag.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - FX Shader Fix

    // swiftlint:disable:next function_body_length
    private func applyFXFix() throws {
        let fx30 = """
        uniform sampler2D texUnit0;
        uniform sampler2D texUnit1;
        uniform float randValue;
        uniform int randMax;
        uniform int randStep;
        uniform int randBias;
        uniform int vertexColor;
        uniform int fogMode;

        void main()
        {
            vec4 tex0 = texture2D(texUnit0, gl_TexCoord[0].xy);
            float texr = tex0[int(randValue * float(randMax)) * randStep + randBias];
            vec4 tex1 = texture2D(texUnit1, vec2(texr, 0.0));
            gl_FragColor = tex1;
        }
        """
        let fx31 = """
        uniform sampler2D texUnit0;
        uniform float randValue;
        uniform int randMax;
        uniform int randStep;
        uniform int randBias;
        uniform int vertexColor;
        uniform int fogMode;

        void main()
        {
            vec4 tex0 = texture2D(texUnit0, gl_TexCoord[0].xy);
            float texr = tex0[int(randValue * float(randMax)) * randStep + randBias];
            gl_FragColor = vec4(vec3(texr), texr);
        }
        """
        let fxtbn30 = """
        uniform sampler2D texUnit0;
        uniform int vertexColor;
        uniform int fogMode;

        void main()
        {
            vec4 tex0 = texture2D(texUnit0, gl_TexCoord[0].xy);
            gl_FragColor = vec4(tex0.rgb, tex0.a);
        }
        """
        let fixes = [
            ("fx.id30.frag", fx30),
            ("fx.id31.frag", fx31),
            ("fx.tbn.id30.frag", fxtbn30)
        ]
        for (name, content) in fixes {
            let url = gameShaderPath.appending(path: name, directoryHint: .notDirectory)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            try content.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Minimal Frag Fix (non-unit object shaders)

    private static let skipSet: Set<String> = [
        "unit.smx3.id8.frag", "unit.smx9.id8.frag",
        "fx.id30.frag", "fx.id31.frag", "fx.tbn.id30.frag",
        "b.frag", "test.config.frag"
    ]

    private func applyMinimalFragFix() throws {
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(at: gameShaderPath, includingPropertiesForKeys: nil)
        let frags = contents.filter { $0.pathExtension == "frag" && !Self.skipSet.contains($0.lastPathComponent) }

        for url in frags {
            guard let original = try? String(contentsOf: url, encoding: .utf8) else { continue }
            if let minimal = makeMinimalFrag(from: original) {
                try minimal.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }

    private func makeMinimalFrag(from source: String) -> String? {
        // Find the primary texture sampler name (e.g. "texUnit0")
        var texVar: String?
        for line in source.components(separatedBy: "\n") {
            if let match = line.range(of: #"texture2D\(([a-zA-Z0-9]+)"#, options: .regularExpression) {
                let substring = String(line[match])
                let inner = substring.replacingOccurrences(of: "texture2D(", with: "")
                texVar = inner
                break
            }
        }
        guard let texName = texVar else { return nil }

        let hasCustColor = source.contains("custColor")
        let useTexAlpha = source.range(of: #"color\.a\s*=\s*[^;]*tex0\.a"#, options: .regularExpression) != nil

        var lines: [String] = []
        lines.append("uniform sampler2D \(texName);")
        if hasCustColor { lines.append("uniform vec4 custColor;") }
        lines.append("void main()")
        lines.append("{")
        lines.append("   vec4 tex0 = texture2D(\(texName), gl_TexCoord[0].xy);")
        if hasCustColor {
            let blend = "   tex0.rgb = mix(tex0.rgb, custColor.rgb*tex0.rgb,"
                + " tex0.a*custColor.a*step(0.15, max(custColor.r, max(custColor.g, custColor.b))));"
            lines.append(blend)
        }
        let alpha = useTexAlpha ? "tex0.a" : "1.0"
        lines.append("   gl_FragColor = vec4(tex0.rgb, \(alpha));")
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    // MARK: - Unit Vertex Repair

    private func bestUnitVertexShaderBackupSource() -> URL? {
        for candidate in unitVertexBackupCandidates() {
            if let urls = try? unitVertexShaderURLs(in: candidate), !urls.isEmpty {
                return candidate
            }
        }
        return nil
    }

    private func unitVertexBackupCandidates() -> [URL] {
        let shaderRoot = gameShaderPath.deletingLastPathComponent()
        let gameDirectory = shaderRoot.deletingLastPathComponent().deletingLastPathComponent()
        let portRoot = gameDirectory.deletingLastPathComponent()
        return [
            shaderRoot.appending(path: "obj_yedek", directoryHint: .isDirectory),
            shaderRoot.appending(path: "obj_before_vert_fix", directoryHint: .isDirectory),
            portRoot.appending(
                path: ".local_backups/working_shader_restore_20260623_005447",
                directoryHint: .isDirectory
            )
        ]
    }

    private func unitVertexShaderURLs(in directory: URL) throws -> [URL] {
        guard FileManager.default.fileExists(atPath: directory.path) else { return [] }
        return try FileManager.default
            .contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { url in
                let name = url.lastPathComponent
                return name.hasPrefix("unit.sm.b") && name.hasSuffix(".vert")
            }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}
