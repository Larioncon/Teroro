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

    var title: String {
        switch self {
        case .always:
            "Завжди"
        case .oneMinute:
            "Якщо відсутній 1 хв"
        case .fiveMinutes:
            "Якщо відсутній 5 хв"
        case .oneHour:
            "Якщо відсутній 1 год"
        case .fiveHours:
            "Якщо відсутній 5 год"
        }
    }

    var lockInterval: TimeInterval {
        rawValue
    }
}
