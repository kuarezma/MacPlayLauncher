import Foundation

struct DisabledGameLauncher: GameLaunching {
    func launch(profile: GameProfile) throws -> GameLaunchResult {
        throw MacPlayError.launchPreparationFailed
    }
}
