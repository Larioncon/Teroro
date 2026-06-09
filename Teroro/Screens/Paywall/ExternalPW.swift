import RevenueCat
import RevenueCatUI
import SwiftUI

struct ExternalPW: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var subscriptionService = SubscriptionService.shared

    var body: some View {
        Group {
            if let offering = subscriptionService.defaultOffering {
                PaywallView(offering: offering, displayCloseButton: true)
                    .paywallCallbacks
            } else {
                PaywallView(displayCloseButton: true)
                    .paywallCallbacks
            }
        }
        .onRequestedDismissal {
            close()
        }
        .task {
            await subscriptionService.bootstrap()
        }
    }

    private func close() {
        appState.isShowPwTrial = false
    }
}

private extension View {
    var paywallCallbacks: some View {
        self
            .onPurchaseCompleted { customerInfo in
                SubscriptionService.shared.updateSubscriptionStatus(from: customerInfo)
                AppState.shared.isShowPwTrial = false
            }
            .onRestoreCompleted { customerInfo in
                SubscriptionService.shared.updateSubscriptionStatus(from: customerInfo)
                AppState.shared.isShowPwTrial = false
            }
    }
}
