//
//  AppConstants.swift
//  Teroro
//
//  Created by Chmil Oleksandr on 4/13/26.
//

import Foundation

struct AppConstants {
    // MARK: - App Info
    static let appID = Secrets.appID
    
    // MARK: - RevenueCat
    static let revenueCatKey = Secrets.revenueCatPublicKey
    static let externalPaywallOfferingID = Secrets.defaultOfferingID

    // MARK: - Subscription Product IDs
    static let weeklyProductID = Secrets.weeklyProductID
    static let monthlyProductID = Secrets.monthlyProductID
    static let yearlyProductID = Secrets.yearlyProductID
    
    static let weeklyTrialProductID = Secrets.weeklyTrialProductID
    static let monthlyTrialProductID = Secrets.monthlyTrialProductID
    static let yearlyTrialProductID = Secrets.yearlyTrialProductID
    
    static let lifetimeProductID = Secrets.lifetimeProductID
    static let yearlySpecialProductID = Secrets.yearlySpecialOfferProductID
    
    // MARK: - Links
    static let termsOfUseLink = Secrets.termsOfUseURL
    static let privacyPolicyLink = Secrets.privacyPolicyURL
    static let contactUsLink = Secrets.contactURL
    static let contactUsEmail = Secrets.supportEmail
    static let appStoreLink = Secrets.appStoreURL

}
