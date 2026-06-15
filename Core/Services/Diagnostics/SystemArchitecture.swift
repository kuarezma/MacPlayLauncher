import Foundation

enum SystemArchitecture: Sendable {
    case appleSilicon
    case intel
    case unknown
}

protocol SystemArchitectureProviding: Sendable {
    var architecture: SystemArchitecture { get }
}

struct CurrentSystemArchitectureProvider: SystemArchitectureProviding {
    var architecture: SystemArchitecture {
        #if arch(arm64)
        .appleSilicon
        #elseif arch(x86_64)
        .intel
        #else
        .unknown
        #endif
    }
}
