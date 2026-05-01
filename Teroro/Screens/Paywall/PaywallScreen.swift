import SwiftUI

struct PaywallScreen: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer(minLength: 0)

                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.blue)
                    .padding(22)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                Text("Преміум доступ")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Зараз це плейсхолдер. Пізніше підключимо реальну підписку та ціни.")
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                Spacer(minLength: 0)

                VStack(spacing: 12) {
                    PrimaryButton(title: "Продовжити", style: .primary, frameHeight: 54) {
                        close()
                    }

                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    close()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Закрити")
            }
        }
    }

    private func close() {
        appState.isShowPaywall = false
        appState.isShowPwTrial = false
        dismiss()
    }
}

#Preview {
    NavigationStack {
        PaywallScreen()
            .environmentObject(AppState())
    }
}

