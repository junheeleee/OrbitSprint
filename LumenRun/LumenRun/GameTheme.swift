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
            [Color(red: 0.025, green: 0.035, blue: 0.075), Color(red: 0.02, green: 0.12, blue: 0.15)]
        case .solar:
            [Color(red: 0.08, green: 0.035, blue: 0.055), Color(red: 0.22, green: 0.08, blue: 0.08)]
        case .mono:
            [Color(red: 0.035, green: 0.04, blue: 0.07), Color(red: 0.10, green: 0.105, blue: 0.14)]
        }
    }

    var feverColors: [Color] {
        switch self {
        case .aurora:
            [Color(red: 0.0, green: 0.85, blue: 0.8), Color(red: 1.0, green: 0.26, blue: 0.64)]
        case .solar:
            [Color(red: 1.0, green: 0.52, blue: 0.15), Color(red: 1.0, green: 0.86, blue: 0.24)]
        case .mono:
            [Color(red: 0.74, green: 0.88, blue: 1.0), Color(red: 0.94, green: 0.74, blue: 1.0)]
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
        case .aurora: SKColor(red: 1.0, green: 0.86, blue: 0.24, alpha: 1)
        case .solar: SKColor(red: 1.0, green: 0.82, blue: 0.20, alpha: 1)
        case .mono: SKColor(red: 0.80, green: 0.88, blue: 1.0, alpha: 1)
        }
    }

    var shardColor: SKColor {
        switch self {
        case .aurora: SKColor(red: 1.0, green: 0.18, blue: 0.48, alpha: 1)
        case .solar: SKColor(red: 0.94, green: 0.10, blue: 0.14, alpha: 1)
        case .mono: SKColor(red: 0.48, green: 0.52, blue: 0.64, alpha: 1)
        }
    }

    var shieldColor: SKColor {
        switch self {
        case .aurora: SKColor(red: 0.1, green: 0.68, blue: 1.0, alpha: 1)
        case .solar: SKColor(red: 0.18, green: 0.82, blue: 1.0, alpha: 1)
        case .mono: SKColor(red: 0.68, green: 0.82, blue: 1.0, alpha: 1)
        }
    }

    var timeCoreColor: SKColor {
        switch self {
        case .aurora: SKColor(red: 0.78, green: 0.36, blue: 1.0, alpha: 1)
        case .solar: SKColor(red: 1.0, green: 0.36, blue: 0.76, alpha: 1)
        case .mono: SKColor(red: 0.82, green: 0.72, blue: 1.0, alpha: 1)
        }
    }

    var feverColor: SKColor {
        switch self {
        case .aurora: SKColor(red: 0.0, green: 0.95, blue: 0.82, alpha: 1)
        case .solar: SKColor(red: 1.0, green: 0.72, blue: 0.18, alpha: 1)
        case .mono: SKColor(red: 0.92, green: 0.95, blue: 1.0, alpha: 1)
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
