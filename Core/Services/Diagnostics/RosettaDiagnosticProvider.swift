import Foundation

struct RosettaDiagnosticProvider: RuntimeDiagnosticProviding {
    private let commandRunner: any CommandRunning
    private let architectureProvider: any SystemArchitectureProviding
    private let timeoutSeconds: TimeInterval

    init(
        commandRunner: any CommandRunning = ProcessCommandRunner(),
        architectureProvider: any SystemArchitectureProviding = CurrentSystemArchitectureProvider(),
        timeoutSeconds: TimeInterval = 2
    ) {
        self.commandRunner = commandRunner
        self.architectureProvider = architectureProvider
        self.timeoutSeconds = timeoutSeconds
    }

    func diagnose() async -> RuntimeDependency {
        switch architectureProvider.architecture {
        case .appleSilicon:
            return await diagnoseAppleSilicon()
        case .intel:
            return dependency(
                status: .notRequired,
                description: "Bu cihazda Rosetta gerekli görünmüyor.",
                missingReason: nil,
                suggestedAction: nil
            )
        case .unknown:
            return dependency(
                status: .unknown,
                description: "Rosetta durumu doğrulanamadı.",
                missingReason: "Sistem mimarisi doğrulanamadı.",
                suggestedAction: nil
            )
        }
    }

    private func diagnoseAppleSilicon() async -> RuntimeDependency {
        do {
            _ = try await commandRunner.run(commandRequest())
            return dependency(
                status: .ready,
                description: "Rosetta kullanılabilir görünüyor.",
                missingReason: nil,
                suggestedAction: nil
            )
        } catch CommandError.nonZeroExit(_) {
            return dependency(
                status: .missing,
                description: "Rosetta kurulu görünmüyor.",
                missingReason: "Rosetta kurulu görünmüyor.",
                suggestedAction: "Rosetta gerekiyorsa Apple’ın resmi kurulum yönergelerini izleyin."
            )
        } catch {
            return dependency(
                status: .unknown,
                description: "Rosetta durumu doğrulanamadı.",
                missingReason: "Rosetta durumu doğrulanamadı.",
                suggestedAction: nil
            )
        }
    }

    private func commandRequest() -> CommandRequest {
        CommandRequest(
            executableURL: URL(fileURLWithPath: "/usr/bin/arch"),
            arguments: ["-x86_64", "/usr/bin/true"],
            environment: [:],
            timeoutSeconds: timeoutSeconds,
            purpose: .rosettaCheck
        )
    }

    private func dependency(
        status: RuntimeDependencyStatus,
        description: String,
        missingReason: String?,
        suggestedAction: String?
    ) -> RuntimeDependency {
        RuntimeDependency(
            displayName: "Rosetta",
            kind: .rosetta,
            status: status,
            version: nil,
            installPath: nil,
            userFacingDescription: description,
            missingReason: missingReason,
            suggestedAction: suggestedAction,
            setupGuide: nil
        )
    }
}
