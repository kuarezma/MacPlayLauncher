enum PerformanceMode: String, Codable, CaseIterable, Sendable {
    case performance
    case balanced
    case coolBatterySafe

    static func recommended(isPortableMac: Bool, isOnBattery: Bool, memoryGB: Int) -> PerformanceMode {
        if isOnBattery || memoryGB <= 8 {
            return .coolBatterySafe
        }

        if isPortableMac {
            return .balanced
        }

        return .performance
    }
}
