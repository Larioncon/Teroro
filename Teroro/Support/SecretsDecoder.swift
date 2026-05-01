import Foundation

enum Secrets {
    
    // MARK: - RevenueCat
    static var appID: String {
        string(for: "APP_ID")
    }
    
    static var revenueCatPublicKey: String {
        string(for: "REVENUECAT_PUBLIC_KEY")
    }
    
    static var defaultOfferingID: String {
        string(for: "DEFAULT_OFFERING_ID")
    }
    
    // MARK: - Subscription Product IDs
    static var weeklyProductID: String {
        string(for: "WEEKLY_PRODUCT_ID")
    }
    
    static var monthlyProductID: String {
        string(for: "MONTHLY_PRODUCT_ID")
    }
    
    static var yearlyProductID: String {
        string(for: "YEARLY_PRODUCT_ID")
    }
    
    static var weeklyTrialProductID: String {
        string(for: "WEEKLY_TRIAL_PRODUCT_ID")
    }
    
    static var monthlyTrialProductID: String {
        string(for: "MONTHLY_TRIAL_PRODUCT_ID")
    }
    
    static var yearlyTrialProductID: String {
        string(for: "YEARLY_TRIAL_PRODUCT_ID")
    }
    
    static var lifetimeProductID: String {
        string(for: "LIFETIME_PRODUCT_ID")
    }
    
    static var yearlySpecialOfferProductID: String {
        string(for: "YEARLY_SPECIAL_OFFER_PRODUCT_ID")
    }
    
    // MARK: - Links & Support
    static var termsOfUseURL: String {
        string(for: "TERMS_OF_USE_URL")
    }
    
    static var privacyPolicyURL: String {
        string(for: "PRIVACY_POLICY_URL")
    }
    
    static var contactURL: String {
        string(for: "CONTACT_URL")
    }
    
    static var supportEmail: String {
        string(for: "SUPPORT_EMAIL")
    }
    
    static var appStoreURL: String {
        string(for: "APP_STORE_URL")
    }
    
    // MARK: - Private Helper
    private static func string(for key: String) -> String {
        guard let value = Bundle.main.infoDictionary?[key] as? String,
              !value.isEmpty else {
            fatalError("\(key) is missing in Secrets.xcconfig")
        }
        return value
    }
}
