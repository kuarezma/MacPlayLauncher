@testable import MacPlayLauncher
import XCTest

final class ShaderPatchServiceTests: XCTestCase {
    var tempRoot: URL!
    var tempDir: URL!
    var service: ShaderPatchService!

    override func setUpWithError() throws {
        tempRoot = FileManager.default.temporaryDirectory
            .appending(path: "ShaderPatchTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        tempDir = tempRoot.appending(path: "obj", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        service = ShaderPatchService(gameShaderPath: tempDir)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempRoot)
    }

    // MARK: - isAlreadyPatched

    func testIsAlreadyPatchedReturnsFalseWhenProbeFileMissing() {
        XCTAssertFalse(service.isAlreadyPatched())
    }

    func testIsAlreadyPatchedReturnsFalseForUnpatchedShader() throws {
        let url = tempDir.appending(path: "hf.pvl.smx3.frag", directoryHint: .notDirectory)
        let original = """
        uniform sampler2D texUnit0;
        void main() {
           vec4 tex0 = texture2D(texUnit0, gl_TexCoord[0].xy);
           gl_FragColor = tex0;
        }
        """
        try original.write(to: url, atomically: true, encoding: .utf8)

        XCTAssertFalse(service.isAlreadyPatched())
    }

    func testIsAlreadyPatchedReturnsTrueWhenFragmentProbesAreMinimal() throws {
        let patched = """
        uniform sampler2D texUnit0;
        void main() {
           vec4 tex0 = texture2D(texUnit0, gl_TexCoord[0].xy);
           gl_FragColor = vec4(tex0.rgb, 1.0);
        }
        """
        for name in ["hf.pvl.smx3.frag", "env.smx3.id3.frag", "unit.smx3.id8.frag"] {
            let url = tempDir.appending(path: name, directoryHint: .notDirectory)
            try patched.write(to: url, atomically: true, encoding: .utf8)
        }

        XCTAssertTrue(service.isAlreadyPatched())
    }

    // MARK: - Unit Vertex Shaders

    func testApplyLeavesUnitVertexShaderUntouched() throws {
        let url = tempDir.appending(path: "unit.sm.b16.id10.vert", directoryHint: .notDirectory)
        let original = """
        #define NBONES 16
        uniform mat4 cameraMVM;
        uniform mat4 boneMatrices[NBONES];
        void main()
        {
           int index=int(gl_MultiTexCoord2.x);
           vec4 aposn=boneMatrices[index]*gl_Vertex;
           gl_Position=gl_ModelViewProjectionMatrix*aposn;
        }
        """
        try original.write(to: url, atomically: true, encoding: .utf8)

        try service.apply()

        let result = try String(contentsOf: url, encoding: .utf8)
        XCTAssertEqual(result, original)
    }

    func testUnitVertexRepairRestoresFromObjYedek() throws {
        let backupDir = tempRoot.appending(path: "obj_yedek", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        let backupURL = backupDir.appending(path: "unit.sm.b42.id22.vert", directoryHint: .notDirectory)
        let original = "#define NBONES 42\nvoid main(){ gl_Position=gl_Vertex; }"
        try original.write(to: backupURL, atomically: true, encoding: .utf8)

        let targetURL = tempDir.appending(path: "unit.sm.b42.id22.vert", directoryHint: .notDirectory)
        try "#define NBONES 42\nvoid main(){ gl_Position=vec4(0.0); }"
            .write(to: targetURL, atomically: true, encoding: .utf8)

        XCTAssertTrue(try service.needsUnitVertexShaderRepair())
        let result = try service.repairUnitVertexShadersFromBestBackupIfAvailable()

        XCTAssertEqual(result.backupSourceURL, backupDir)
        XCTAssertEqual(result.restoredFileNames, ["unit.sm.b42.id22.vert"])
        XCTAssertEqual(try String(contentsOf: targetURL, encoding: .utf8), original)
    }

    // MARK: - Minimal Frag Fix

    func testApplyMinimalFragFixGeneratesSimplifiedShader() throws {
        let fragURL = tempDir.appending(path: "object.id5.frag", directoryHint: .notDirectory)
        let original = """
        uniform sampler2D texUnit0;
        uniform vec4 custColor;
        uniform int fogMode;
        uniform float fogDensity;
        void main()
        {
           vec4 tex0 = texture2D(texUnit0, gl_TexCoord[0].xy);
           vec4 color;
           color.rgb = tex0.rgb * gl_Color.rgb;
           color.a = 1.0;
           gl_FragColor = color;
        }
        """
        try original.write(to: fragURL, atomically: true, encoding: .utf8)

        try service.apply()

        let result = try String(contentsOf: fragURL, encoding: .utf8)
        XCTAssertTrue(result.contains("texture2D(texUnit0"))
        XCTAssertFalse(result.contains("fogDensity"))
        XCTAssertFalse(result.contains("fogMode"))
    }

    // MARK: - Backup

    func testCreateBackupCopiesDirectory() throws {
        let shader = tempDir.appending(path: "unit.sm.b1.id1.vert", directoryHint: .notDirectory)
        try "void main(){}".write(to: shader, atomically: true, encoding: .utf8)

        try service.createBackupIfNeeded()

        let backupPath = tempRoot.appending(path: "obj_yedek", directoryHint: .isDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupPath.path))
    }

    func testCreateBackupIsIdempotent() throws {
        let backupURL = tempRoot.appending(path: "obj_yedek", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: backupURL, withIntermediateDirectories: true)
        let marker = backupURL.appending(path: "marker.txt", directoryHint: .notDirectory)
        try "original".write(to: marker, atomically: true, encoding: .utf8)

        // Should not overwrite existing backup
        try service.createBackupIfNeeded()

        let markerContent = try String(contentsOf: marker, encoding: .utf8)
        XCTAssertEqual(markerContent, "original")
    }
}
