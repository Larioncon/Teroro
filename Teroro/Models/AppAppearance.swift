import SwiftUI

enum AppAppearance: Int, CaseIterable, Identifiable {
    case system = 0
    case light = 1
    case dark = 2

    var id: Int { rawValue }

    @MainActor
    var title: String {
        switch self {
        case .system: return LanguageManager.shared.localizedString(forKey: "appearance_system")
        case .light: return LanguageManager.shared.localizedString(forKey: "appearance_light")
        case .dark: return LanguageManager.shared.localizedString(forKey: "appearance_dark")
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

