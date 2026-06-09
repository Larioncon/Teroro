import Foundation
import RevenueCat

@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published private(set) var isPremium: Bool
    @Published private(set) var isLoading = false
    @Published private(set) var isPurchasing = false
    @Published private(set) var errorMessage: String?

    private(set) var offerings: Offerings?
    private(set) var defaultOffering: Offering?

    private let defaults: UserDefaults
    private var isConfigured = false

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isPremium = defaults.bool(forKey: Self.isPremiumKey)
    }

    func configureIfNeeded() {
        guard !isConfigured else { return }
        Purchases.configure(withAPIKey: AppConstants.revenueCatKey)
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        isConfigured = true
    }

    func bootstrap() async {
        configureIfNeeded()
        isLoading = true
        defer { isLoading = false }

        do {
            offerings = try await Purchases.shared.offerings()
            defaultOffering = offerings?.all[AppConstants.externalPaywallOfferingID] ?? offerings?.current
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionStatus(from: customerInfo)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase(productID: String) async -> Bool {
        configureIfNeeded()
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            if offerings == nil {
                offerings = try await Purchases.shared.offerings()
                defaultOffering = offerings?.all[AppConstants.externalPaywallOfferingID] ?? offerings?.current
            }

            guard let package = package(for: productID) else {
                errorMessage = "Product not found. Please try again later."
                return false
            }

            let result = try await Purchases.shared.purchase(package: package)
            updateSubscriptionStatus(from: result.customerInfo)
            return !result.userCancelled && isPremium
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func restore() async -> Bool {
        configureIfNeeded()
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateSubscriptionStatus(from: customerInfo)
            return isPremium
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func refreshCustomerInfo() async {
        configureIfNeeded()
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionStatus(from: customerInfo)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func updateSubscriptionStatus(from customerInfo: CustomerInfo) {
        let activeEntitlements = customerInfo.entitlements.active
        let hasActiveEntitlement = activeEntitlements.contains { _, entitlement in
            entitlement.expirationDate.map { $0 > Date() } ?? true
        }

        isPremium = hasActiveEntitlement
        defaults.set(isPremium, forKey: Self.isPremiumKey)

        if let expirationDate = activeEntitlements.compactMap({ $0.value.expirationDate }).max() {
            defaults.set(expirationDate, forKey: Self.subscriptionEndDateKey)
        } else {
            defaults.removeObject(forKey: Self.subscriptionEndDateKey)
        }
    }

    func localizedPrice(for productID: String) -> String {
        package(for: productID)?.storeProduct.localizedPriceString ?? fallbackPrice(for: productID)
    }

    private func package(for productID: String) -> Package? {
        let packages = allPackages()
        return packages.first { package in
            package.storeProduct.productIdentifier == productID || package.identifier == productID
        }
    }

    private func allPackages() -> [Package] {
        let offeringPackages = offerings?.all.values.flatMap(\.availablePackages) ?? []
        let defaultPackages = defaultOffering?.availablePackages ?? []
        return defaultPackages + offeringPackages
    }

    private func fallbackPrice(for productID: String) -> String {
        switch productID {
        case AppConstants.weeklyProductID:
            return "$0.99"
        case AppConstants.weeklyTrialProductID:
            return "$1.49"
        case AppConstants.monthlyProductID:
            return "$1.99"
        case AppConstants.monthlyTrialProductID:
            return "$2.99"
        case AppConstants.yearlyProductID:
            return "$14.99"
        case AppConstants.yearlyTrialProductID:
            return "$19.99"
        case AppConstants.yearlySpecialProductID:
            return "$9.99"
        default:
            return ""
        }
    }
}

private extension SubscriptionService {
    static let isPremiumKey = "isPremiumUser"
    static let subscriptionEndDateKey = "subscriptionEndDate"
}
