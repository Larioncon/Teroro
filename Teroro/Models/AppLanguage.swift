import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case ukrainian = "uk"
    case german = "de"
    case russian = "ru"

    var id: String { rawValue }
    var code: String { rawValue }

    /// Primary international name (e.g. English, Ukrainian, German, Russian)
    var displayName: String {
        switch self {
        case .english: return "English"
        case .ukrainian: return "Ukrainian"
        case .german: return "German"
        case .russian: return "Russian"
        }
    }

    /// Native endonym in the language itself
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .ukrainian: return "Українська"
        case .german: return "Deutsch"
        case .russian: return "Русский"
        }
    }

    /// Detects device preferred language and matches against the 4 supported languages.
    /// If none match, defaults to English (US).
    static func detectDefaultLanguage() -> AppLanguage {
        for preferred in Locale.preferredLanguages {
            let code = preferred.lowercased()
            if code.hasPrefix("de") {
                return .german
            } else if code.hasPrefix("uk") {
                return .ukrainian
            } else if code.hasPrefix("ru") {
                return .russian
            } else if code.hasPrefix("en") {
                return .english
            }
        }
        return .english
    }
}
