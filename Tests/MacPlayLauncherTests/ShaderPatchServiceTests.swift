import XCTest
@testable import MacPlayLauncher

final class ShaderPatchServiceTests: XCTestCase {
    var tempDir: URL!
    var service: ShaderPatchService!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appending(path: "ShaderPatchTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        service = ShaderPatchService(gameShaderPath: tempDir)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    // MARK: - isAlreadyPatched

    func testIsAlreadyPatchedReturnsFalseWhenProbeFileMissing() {
        XCTAssertFalse(service.isAlreadyPatched())
    }

    func testIsAlreadyPatchedReturnsFalseForUnpatchedShader() throws {
        let url = tempDir.appending(path: "unit.sm.b42.id22.vert", directoryHint: .notDirectory)
        let original = """
        #define NBONES 42
        uniform mat4 boneMatrices[NBONES];
        void main() {
           int index=int(gl_MultiTexCoord2.x);
           vec4 aposn=boneMatrices[index]*gl_Vertex;
           gl_Position=gl_ModelViewProjectionMatrix*aposn;
        }
        """
        try original.write(to: url, atomically: true, encoding: .utf8)

        XCTAssertFalse(service.isAlreadyPatched())
    }

    func testIsAlreadyPatchedReturnsTrueWhenForLoopPresent() throws {
        let url = tempDir.appending(path: "unit.sm.b42.id22.vert", directoryHint: .notDirectory)
        let patched = """
        #define NBONES 42
        uniform mat4 boneMatrices[NBONES];
        void main() {
           int index=int(gl_MultiTexCoord2.x);
           mat4 bone=mat4(0.0);
           for(int i=0;i<NBONES;i++){ if(i==index){ bone=boneMatrices[i]; } }
           gl_Position=gl_ModelViewProjectionMatrix*(bone*gl_Vertex);
        }
        """
        try patched.write(to: url, atomically: true, encoding: .utf8)

        XCTAssertTrue(service.isAlreadyPatched())
    }

    // MARK: - Bone Fix

    func testApplyBoneFixWritesForLoopToVertShader() throws {
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
        XCTAssertTrue(result.contains("for(int i=0;i<NBONES;i++)"))
        XCTAssertTrue(result.contains("#define NBONES 16"))
        XCTAssertFalse(result.contains("boneMatrices[index]"))
    }

    func testApplyBoneFixPreservesNBONESCount() throws {
        for n in [1, 3, 5, 22, 42] {
            let name = "unit.sm.b\(n).test.vert"
            let url = tempDir.appending(path: name, directoryHint: .notDirectory)
            let original = "#define NBONES \(n)\nuniform mat4 boneMatrices[NBONES];\nvoid main(){}"
            try original.write(to: url, atomically: true, encoding: .utf8)
        }

        try service.apply()

        for n in [1, 3, 5, 22, 42] {
            let name = "unit.sm.b\(n).test.vert"
            let url = tempDir.appending(path: name, directoryHint: .notDirectory)
            let result = try String(contentsOf: url, encoding: .utf8)
            XCTAssertTrue(result.contains("#define NBONES \(n)"), "NBONES mismatch for n=\(n)")
        }
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

        let backupPath = tempDir.deletingLastPathComponent().appending(path: "obj_yedek", directoryHint: .isDirectory)
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupPath.path))
        try? FileManager.default.removeItem(at: backupPath)
    }

    func testCreateBackupIsIdempotent() throws {
        let backupURL = tempDir.deletingLastPathComponent().appending(path: "obj_yedek", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: backupURL, withIntermediateDirectories: true)
        let marker = backupURL.appending(path: "marker.txt", directoryHint: .notDirectory)
        try "original".write(to: marker, atomically: true, encoding: .utf8)

        // Should not overwrite existing backup
        try service.createBackupIfNeeded()

        let markerContent = try String(contentsOf: marker, encoding: .utf8)
        XCTAssertEqual(markerContent, "original")
        try? FileManager.default.removeItem(at: backupURL)
    }
}
