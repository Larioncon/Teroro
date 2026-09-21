//
//  SubscriptionPlanTests.swift
//  TeroroUnitTests
//
//  Created by Chmil Oleksandr on 21.09.26.
//

import Testing
@testable import Teroro

struct SubscriptionPlanTests {

    @Test("Subscription plan periods have correct identifiers and titles")
    func subscriptionPlanPeriodProperties() {
        #expect(SubscriptionPlanPeriod.week.id == "week")
        #expect(SubscriptionPlanPeriod.week.title == "Week")
        #expect(SubscriptionPlanPeriod.week.productTitle == "Get weekly plan")

        #expect(SubscriptionPlanPeriod.month.id == "month")
        #expect(SubscriptionPlanPeriod.month.title == "Month")
        #expect(SubscriptionPlanPeriod.month.productTitle == "Get monthly plan")

        #expect(SubscriptionPlanPeriod.year.id == "year")
        #expect(SubscriptionPlanPeriod.year.title == "Year")
        #expect(SubscriptionPlanPeriod.year.productTitle == "Get annual plan")
    }

    @Test("Product IDs without trial match the expected constants")
    func productIDsWithoutTrial() {
        #expect(SubscriptionPlanPeriod.week.productID(isTrialEnabled: false) == AppConstants.weeklyProductID)
        #expect(SubscriptionPlanPeriod.month.productID(isTrialEnabled: false) == AppConstants.monthlyProductID)
        #expect(SubscriptionPlanPeriod.year.productID(isTrialEnabled: false) == AppConstants.yearlyProductID)
    }

    @Test("Product IDs with trial enabled match the expected constants")
    func productIDsWithTrial() {
        #expect(SubscriptionPlanPeriod.week.productID(isTrialEnabled: true) == AppConstants.weeklyTrialProductID)
        #expect(SubscriptionPlanPeriod.month.productID(isTrialEnabled: true) == AppConstants.monthlyTrialProductID)
        #expect(SubscriptionPlanPeriod.year.productID(isTrialEnabled: true) == AppConstants.yearlyTrialProductID)
    }
}
