import SwiftUI

struct SplashRootView: View {
    let persistenceController: PersistenceController
    @EnvironmentObject private var appState: AppState

    @State private var isShowingSplash = true
    @StateObject private var onboardingVM = OnboardingFlowVM()
    @StateObject private var onboardingRouter = AppRouter()
    @State private var hideMainUntilSplashCompletes = true

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
                        default:
                            EmptyView()
                        }
                    }
            }
            .opacity(onboardingRouter.path.count > 0 ? 1 : 0)
            .allowsHitTesting(onboardingRouter.path.count > 0)
        }
        .task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            onboardingVM.navigationRouter = onboardingRouter
            onboardingVM.appState = appState
            if onboardingVM.shouldShowOnboarding {
                var tx = Transaction()
                tx.animation = nil
                withTransaction(tx) {
                    onboardingRouter.push(.onboarding)
                }
            }

            withAnimation(.easeOut(duration: 0.25)) {
                isShowingSplash = false
                hideMainUntilSplashCompletes = false
            }
        }
    }
}

#Preview {
    SplashRootView(persistenceController: .shared)
        .environmentObject(AppState())
}
