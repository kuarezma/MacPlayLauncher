import Foundation

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
}
