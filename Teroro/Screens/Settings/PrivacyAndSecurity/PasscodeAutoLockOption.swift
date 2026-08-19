import Foundation

enum PasscodeAutoLockOption: Double, CaseIterable, Hashable, Identifiable {
    case disabled = -1
    case oneMinute = 60
    case fiveMinutes = 300
    case oneHour = 3600
    case fiveHours = 18000

    var id: Double { rawValue }

    var title: String {
        switch self {
        case .disabled:
            "Вимкнено"
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

    var lockInterval: TimeInterval? {
        rawValue < 0 ? nil : rawValue
    }
}
