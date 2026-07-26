import SwiftUI

struct SplashRootView: View {
    let persistenceController: PersistenceController
    @EnvironmentObject private var appState: AppState

    @State private var isShowingSplash = true
    @StateObject private var onboardingVM = OnboardingFlowVM()
    @StateObject private var onboardingRouter = AppRouter()
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var hideMainUntilSplashCompletes = true
    @AppStorage("appAppearance") private var appearanceRawValue: Int = AppAppearance.system.rawValue

    private var preferredColorScheme: ColorScheme? {
        (AppAppearance(rawValue: appearanceRawValue) ?? .system).preferredColorScheme
    }

    var body: some View {
        ZStack {
            AppRootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .opacity((hideMainUntilSplashCompletes || onboardingRouter.path.count > 0) ? 0 : 1)

            if isShowingSplash {
                SplashView()
                    .transition(.opacity)
            }

            NavigationStack(path: $onboardingRouter.path) {
                Color.clear
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .onboarding:
                            OnboardingFlowView(viewModel: onboardingVM)
                                .environmentObject(appState)
                        case .onboardingPaywall:
                            OnboardingPaywallView(onboardingRouter: onboardingRouter)
                                .environmentObject(appState)
                        default:
                            EmptyView()
                        }
                    }
            }
            .opacity(onboardingRouter.path.count > 0 ? 1 : 0)
            .allowsHitTesting(onboardingRouter.path.count > 0)
        }
        .preferredColorScheme(preferredColorScheme)
        .task {
            async let splashDelay: Void = Task.sleepIgnoringCancellation(nanoseconds: 3_000_000_000)
            await subscriptionService.bootstrap()
            await splashDelay

            onboardingVM.navigationRouter = onboardingRouter
            onboardingVM.appState = appState
            if onboardingVM.shouldShowOnboarding {
                var tx = Transaction()
                tx.animation = nil
                withTransaction(tx) {
                    onboardingRouter.push(.onboarding)
                }
            } else if !subscriptionService.isPremium {
                appState.isShowPwTrial = true
            }

            withAnimation(.easeOut(duration: 0.25)) {
                isShowingSplash = false
                hideMainUntilSplashCompletes = false
            }
        }
    }
}

private extension Task where Success == Never, Failure == Never {
    static func sleepIgnoringCancellation(nanoseconds duration: UInt64) async {
        try? await Task.sleep(nanoseconds: duration)
    }
}

#Preview {
    SplashRootView(persistenceController: .shared)
        .environmentObject(AppState())
}
