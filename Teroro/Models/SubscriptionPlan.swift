import Foundation

enum SubscriptionPlanPeriod: String, CaseIterable, Identifiable {
    case week
    case month
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week:
            return "Week"
        case .month:
            return "Month"
        case .year:
            return "Year"
        }
    }

    @MainActor
    var localizedTitle: String {
        switch self {
        case .week:
            return LanguageManager.shared.localizedString(forKey: "plan_period_week")
        case .month:
            return LanguageManager.shared.localizedString(forKey: "plan_period_month")
        case .year:
            return LanguageManager.shared.localizedString(forKey: "plan_period_year")
        }
    }

    var productTitle: String {
        switch self {
        case .week:
            return "Get weekly plan"
        case .month:
            return "Get monthly plan"
        case .year:
            return "Get annual plan"
        }
    }

    @MainActor
    var localizedProductTitle: String {
        switch self {
        case .week:
            return LanguageManager.shared.localizedString(forKey: "plan_get_weekly")
        case .month:
            return LanguageManager.shared.localizedString(forKey: "plan_get_monthly")
        case .year:
            return LanguageManager.shared.localizedString(forKey: "plan_get_annual")
        }
    }

    func productID(isTrialEnabled: Bool) -> String {
        switch (self, isTrialEnabled) {
        case (.week, false):
            return AppConstants.weeklyProductID
        case (.month, false):
            return AppConstants.monthlyProductID
        case (.year, false):
            return AppConstants.yearlyProductID
        case (.week, true):
            return AppConstants.weeklyTrialProductID
        case (.month, true):
            return AppConstants.monthlyTrialProductID
        case (.year, true):
            return AppConstants.yearlyTrialProductID
        }
    }
}
