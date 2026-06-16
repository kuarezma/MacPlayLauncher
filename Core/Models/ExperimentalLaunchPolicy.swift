import Foundation

struct ExperimentalLaunchPolicy: Equatable, Sendable {
    let isEnabled: Bool

    static let experimental = ExperimentalLaunchPolicy(isEnabled: true)
    static let disabled = ExperimentalLaunchPolicy(isEnabled: false)
}
