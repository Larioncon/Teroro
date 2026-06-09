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
