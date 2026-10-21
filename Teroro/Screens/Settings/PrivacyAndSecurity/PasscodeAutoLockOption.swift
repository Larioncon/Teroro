import Foundation

enum PasscodeAutoLockOption: Double, CaseIterable, Hashable, Identifiable {
    case always = 0
    case oneMinute = 60
    case fiveMinutes = 300
    case oneHour = 3600
    case fiveHours = 18000

    var id: Double { rawValue }

    init(rawValue: Double) {
        switch rawValue {
        case 60: self = .oneMinute
        case 300: self = .fiveMinutes
        case 3600: self = .oneHour
        case 18000: self = .fiveHours
        default: self = .always
        }
    }

    @MainActor
    var localizedTitle: String {
        switch self {
        case .always:
            LanguageManager.shared.localizedString(forKey: "security.autolock.always")
        case .oneMinute:
            LanguageManager.shared.localizedString(forKey: "security.autolock.1min")
        case .fiveMinutes:
            LanguageManager.shared.localizedString(forKey: "security.autolock.5min")
        case .oneHour:
            LanguageManager.shared.localizedString(forKey: "security.autolock.1hour")
        case .fiveHours:
            LanguageManager.shared.localizedString(forKey: "security.autolock.5hours")
        }
    }

    @MainActor
    var title: String {
        localizedTitle
    }

    var lockInterval: TimeInterval {
        rawValue
    }
}
