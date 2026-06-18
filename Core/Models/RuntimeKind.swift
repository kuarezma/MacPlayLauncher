enum RuntimeKind: String, Codable, CaseIterable, Sendable {
    case wineDXVKMoltenVK
    case wineD3DMetalExperimental
    case wineDXMTExperimental
    case systemWineFallback
    case crossOver
}

