import SwiftUI
import UIKit

struct PaywallScreen: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var selectedPeriod: SubscriptionPlanPeriod = .week
    @State private var isTrialEnabled = false

    private var selectedProductID: String {
        selectedPeriod.productID(isTrialEnabled: isTrialEnabled)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.primaryColor.opacity(0.18),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                topBar

                Spacer(minLength: 4)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(Color.primaryColor)
                    .frame(width: 116, height: 116)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().strokeBorder(Color.primaryColor.opacity(0.25), lineWidth: 1))

                VStack(spacing: 8) {
                    Text("Unlock Pro")
                        .font(.system(size: 32, weight: .bold))

                    Text("Keep terms, reminders and focus tools fully available.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                }

                VStack(spacing: 10) {
                    ForEach(SubscriptionPlanPeriod.allCases) { period in
                        PlanOptionView(
                            period: period,
                            price: subscriptionService.localizedPrice(for: period.productID(isTrialEnabled: isTrialEnabled)),
                            isTrialEnabled: isTrialEnabled,
                            isSelected: selectedPeriod == period
                        ) {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                selectedPeriod = period
                            }
                        }
                    }
                }
                .padding(.top, 4)

                TrialToggleView(isTrialEnabled: $isTrialEnabled)

                Spacer(minLength: 0)

                VStack(spacing: 12) {
                    Button {
                        Task {
                            let didPurchase = await subscriptionService.purchase(productID: selectedProductID)
                            if didPurchase {
                                close()
                            }
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if subscriptionService.isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            }

                            Text(subscriptionService.isPurchasing ? "Processing..." : "Continue")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(subscriptionService.isPurchasing ? Color.secondary.opacity(0.35) : Color.primaryColor, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(subscriptionService.isPurchasing)

                    footerLinks
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 4)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .swipeBackGestureEnabled()
        .task {
            await subscriptionService.bootstrap()
        }
        .alert("Error", isPresented: Binding(get: {
            subscriptionService.errorMessage != nil
        }, set: { newValue in
            if !newValue {
                subscriptionService.clearError()
            }
        }), actions: {
            Button("OK") {
                subscriptionService.clearError()
            }
        }, message: {
            Text(subscriptionService.errorMessage ?? "")
        })
    }

    private var topBar: some View {
        HStack {
            Button {
                close()
            } label: {
                Image(systemName: "chevron.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")

            Spacer()
        }
    }

    private var footerLinks: some View {
        HStack(spacing: 12) {
            Button("Restore") {
                Task {
                    let didRestore = await subscriptionService.restore()
                    if didRestore {
                        close()
                    }
                }
            }

            Text("•")
                .foregroundStyle(.secondary)

            Button("Terms and conditions") {
                open(AppConstants.termsOfUseLink)
            }

            Text("•")
                .foregroundStyle(.secondary)

            Button("Privacy policy") {
                open(AppConstants.privacyPolicyLink)
            }
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .disabled(subscriptionService.isPurchasing)
    }

    private func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        openURL(url)
    }

    private func close() {
//        appState.isShowPaywall = false
        dismiss()
    }
}


private struct PlanOptionView: View {
    let period: SubscriptionPlanPeriod
    let price: String
    let isTrialEnabled: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(period.title)
                        .font(.title3.weight(.bold))

                    Text(isTrialEnabled ? "Get 3 Days Free Trial" : period.productTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(price)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.primaryColor : .secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 74)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? Color.primaryColor.opacity(0.2) : Color(.systemBackground))
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? Color.primaryColor.opacity(0.7) : Color.secondary.opacity(0.16), lineWidth: 1.2)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct TrialToggleView: View {
    @Binding var isTrialEnabled: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("Free Trial \(isTrialEnabled ? "Enabled" : "Disabled")")
                    .font(.headline)
                Text(isTrialEnabled ? "Plans include 3 days free trial." : "Plans start without trial.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isTrialEnabled.animation(.spring(response: 0.28, dampingFraction: 0.82)))
                .labelsHidden()
                .tint(.primaryColor)
        }
        .padding(16)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.16), lineWidth: 1)
        }
    }
}

#Preview {
    PaywallScreen()
        .environmentObject(AppState())
}
