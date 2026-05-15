import SpriteKit
import SwiftUI

enum GameTheme: String, CaseIterable, Identifiable {
    case aurora
    case solar
    case mono

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .aurora: "theme.aurora"
        case .solar: "theme.solar"
        case .mono: "theme.mono"
        }
    }

    var backgroundColors: [Color] {
        switch self {
        case .aurora:
            [Color(red: 0.05, green: 0.06, blue: 0.09), Color(red: 0.01, green: 0.13, blue: 0.16)]
        case .solar:
            [Color(red: 0.10, green: 0.06, blue: 0.06), Color(red: 0.22, green: 0.11, blue: 0.03)]
        case .mono:
            [Color(red: 0.04, green: 0.05, blue: 0.07), Color(red: 0.11, green: 0.12, blue: 0.14)]
        }
    }

    var playerColor: SKColor {
        switch self {
        case .aurora: SKColor(red: 0.0, green: 0.84, blue: 0.8, alpha: 1)
        case .solar: SKColor(red: 1.0, green: 0.45, blue: 0.18, alpha: 1)
        case .mono: SKColor(red: 0.86, green: 0.92, blue: 1.0, alpha: 1)
        }
    }

    var sparkColor: SKColor {
        switch self {
        case .aurora: SKColor(red: 1.0, green: 0.83, blue: 0.26, alpha: 1)
        case .solar: SKColor(red: 1.0, green: 0.84, blue: 0.42, alpha: 1)
        case .mono: SKColor(red: 0.76, green: 0.82, blue: 0.9, alpha: 1)
        }
    }

    var shardColor: SKColor {
        switch self {
        case .aurora: SKColor(red: 1.0, green: 0.21, blue: 0.32, alpha: 1)
        case .solar: SKColor(red: 0.85, green: 0.12, blue: 0.08, alpha: 1)
        case .mono: SKColor(red: 0.42, green: 0.46, blue: 0.55, alpha: 1)
        }
    }

    var accentColor: Color {
        switch self {
        case .aurora: Color(red: 0.04, green: 0.74, blue: 0.72)
        case .solar: Color(red: 1.0, green: 0.48, blue: 0.2)
        case .mono: Color(red: 0.72, green: 0.78, blue: 0.88)
        }
    }
}
