import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var authVM = AuthVM()
    @AppStorage("appAppearance") private var appearanceRawValue: Int = AppAppearance.system.rawValue

    private var preferredColorScheme: ColorScheme? {
        (AppAppearance(rawValue: appearanceRawValue) ?? .system).preferredColorScheme
    }

    var body: some View {
        Group {
            if authVM.isLoggedIn, authVM.isResolvingProfile {
                ProgressView()
                    .controlSize(.large)
            } else if authVM.needsProfileSetup {
                SetupAuthScreen(viewModel: SetupAuthVM())
            } else if authVM.isLoggedIn {
                SessionContainerView()
            } else {
                AuthScreen(viewModel: authVM)
            }
        }
        .preferredColorScheme(preferredColorScheme)
//        .fullScreenCover(isPresented: $appState.isShowPaywall) {
//            PaywallScreen()
//                .environmentObject(appState)
//        }
        .fullScreenCover(isPresented: $appState.isShowPwTrial) {
            OnboardingPaywallView()
                .environmentObject(appState)
        }
        .alert(item: $appState.alertData) { data in
            Alert(
                title: Text(data.title),
                message: Text(data.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

/// A container for the authenticated session, ensuring all state is purged on logout.
private struct SessionContainerView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var navigator = AppRouter()
    @StateObject private var homeVM = HomeVM()
    @StateObject private var mapVM = TermsMapVM()
    @StateObject private var pomodoroVM = PomodoroVM()
    @StateObject private var settingsVM = SettingsVM()
    @AppStorage("isFaceIDEnabled") private var isFaceIDEnabled = false
    @AppStorage("isPasscodeEnabled") private var isPasscodeEnabled = false
    @AppStorage("userPasscode") private var userPasscode = ""
    @AppStorage("passcodeAutoLockInterval") private var passcodeAutoLockInterval = PasscodeAutoLockOption.oneMinute.rawValue
    @AppStorage("lastInactiveTimestamp") private var lastInactiveTimestamp: Double = 0
    @State private var isLocked = false

    var body: some View {
        ZStack {
            TabView(selection: $navigator.selectedTab) {
                NavigationStack(path: $navigator.termsPath) {
                    HomeView(
                        viewModel: homeVM,
                        onAddTerm: { navigator.push(.addTerm) },
                        onDeleteTerm: homeVM.deleteTerm
                    )
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .onboarding:
                            EmptyView()
                        case .addTerm:
                            AddTermView(
                                onSave: {
                                    homeVM.fetchTerms()
                                    navigator.pop()
                                },
                                onCancel: { navigator.pop() }
                            )
                        case .editTerm(let id):
                            EditTermView(
                                termID: id,
                                onSave: {
                                    homeVM.fetchTerms()
                                    navigator.pop()
                                },
                                onCancel: { navigator.pop() }
                            )
                        case .pastTerms:
                            PastTermsView(viewModel: homeVM, onDeleteTerm: homeVM.deleteTerm)
                        case .settings:
                            SettingsView(
                                viewModel: settingsVM,
                                onShowPaywall: { navigator.push(.pw) },
                                onShowAppearance: { navigator.push(.appearance) },
                                onShowPrivacyAndSecurity: { navigator.push(.privacyAndSecurity) }
                            )
                        case .appearance:
                            AppearanceView(viewModel: settingsVM)
                        case .privacyAndSecurity:
                            PrivacyAndSecurityView(viewModel: settingsVM)
                        case .pw:
                            PaywallScreen()
                                .environmentObject(appState)
                        case .onboardingPaywall:
                            EmptyView()
                        }
                    }
                }
                .tabItem {
                    Label("Терміни", systemImage: "calendar")
                }
                .tag(AppRouter.Tab.terms)

                TermsMapView(viewModel: mapVM, terms: homeVM.terms, isLoading: homeVM.isLoading)
                    .tabItem {
                        Label("Мапа", systemImage: "map")
                    }
                    .tag(AppRouter.Tab.map)

                NavigationStack {
                    PomodoroView(viewModel: pomodoroVM)
                }
                .tabItem {
                    Label("Таймер", systemImage: "timer")
                }
                .tag(AppRouter.Tab.timer)

                NavigationStack(path: $navigator.profilePath) {
                    SettingsView(
                        viewModel: settingsVM,
                        onShowPaywall: { navigator.push(.pw) },
                        onShowAppearance: { navigator.push(.appearance) },
                        onShowPrivacyAndSecurity: { navigator.push(.privacyAndSecurity) }
                    )
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .appearance:
                            AppearanceView(viewModel: settingsVM)
                        case .privacyAndSecurity:
                            PrivacyAndSecurityView(viewModel: settingsVM)
                        case .pw:
                            PaywallScreen()
                                .environmentObject(appState)
                        default:
                            EmptyView()
                        }
                    }
                }
                .tabItem {
                    Label("Профіль", systemImage: "person.crop.circle")
                }
                .tag(AppRouter.Tab.profile)
            }

            if isLocked, isPasscodeEnabled, !userPasscode.isEmpty {
                AppLockScreen(
                    passcode: userPasscode,
                    isFaceIDEnabled: isFaceIDEnabled,
                    onUnlock: unlockSession
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isLocked)
        .onAppear {
            checkAutoLock()
            processPendingDeepLink()
        }
        .onChange(of: scenePhase) { phase in
            handleScenePhaseChange(phase)
        }
        .onChange(of: isPasscodeEnabled) { enabled in
            if !enabled {
                isLocked = false
                lastInactiveTimestamp = 0
            } else {
                checkAutoLock()
            }
        }
        .onChange(of: appState.pendingDeepLink) { _ in
            processPendingDeepLink()
        }
    }

    private var autoLockOption: PasscodeAutoLockOption {
        PasscodeAutoLockOption(rawValue: passcodeAutoLockInterval)
    }

    private func checkAutoLock() {
        guard isPasscodeEnabled, !userPasscode.isEmpty else {
            isLocked = false
            return
        }

        guard !isLocked else { return }

        guard lastInactiveTimestamp > 0 else {
            isLocked = true
            return
        }

        let elapsed = Date.now.timeIntervalSince1970 - lastInactiveTimestamp
        if elapsed >= autoLockOption.lockInterval {
            isLocked = true
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            checkAutoLock()
        case .inactive, .background:
            if isPasscodeEnabled, !userPasscode.isEmpty {
                lastInactiveTimestamp = Date.now.timeIntervalSince1970
            }
        @unknown default:
            break
        }
    }

    private func unlockSession() {
        isLocked = false
        lastInactiveTimestamp = Date.now.timeIntervalSince1970
        processPendingDeepLink()
    }

    private func processPendingDeepLink() {
        guard let destination = appState.pendingDeepLink else { return }
        guard !isLocked else { return }

        navigator.selectedTab = .terms
        navigator.popToRoot(tab: .terms)

        switch destination {
        case .addTerm:
            navigator.push(.addTerm, tab: .terms)
        case .editTerm(let id):
            navigator.push(.editTerm(id), tab: .terms)
        }

        appState.pendingDeepLink = nil
    }
}


#Preview {
    AppRootView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(AppState())
}
