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
    @StateObject private var navigator = AppRouter()
    @StateObject private var homeVM = HomeVM()
    @StateObject private var mapVM = TermsMapVM()
    @StateObject private var pomodoroVM = PomodoroVM()

    var body: some View {
        TabView {
            NavigationStack(path: $navigator.path) {
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
                        TermFormView(
                            viewModel: AddTermVM(),
                            title: "Новий термін",
                            onSave: {
                                homeVM.fetchTerms()
                                navigator.pop()
                            },
                            onCancel: navigator.pop
                        )
                    case .editTerm(let id):
                        TermFormView(
                            viewModel: EditTermVM(termID: id),
                            title: "Редагувати",
                            onSave: {
                                homeVM.fetchTerms()
                                navigator.pop()
                            },
                            onCancel: navigator.pop
                        )
                    case .pastTerms:
                        PastTermsView(viewModel: homeVM, onDeleteTerm: homeVM.deleteTerm)
                    case .settings:
                        SettingsView(
                            viewModel: SettingsVM(appState: appState),
                            onShowPaywall: { navigator.push(.pw) },
                            onShowAppearance: { navigator.push(.appearance) }
                        )
                    case .appearance:
                        AppearanceView(viewModel: SettingsVM(appState: appState))
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

            TermsMapView(viewModel: mapVM, terms: homeVM.terms, isLoading: homeVM.isLoading)
                .tabItem {
                    Label("Мапа", systemImage: "map")
                }

            NavigationStack {
                PomodoroView(viewModel: pomodoroVM)
            }
            .tabItem {
                Label("Таймер", systemImage: "timer")
            }

            NavigationStack(path: $navigator.path) {
                SettingsView(
                    viewModel: SettingsVM(appState: appState),
                    onShowPaywall: { navigator.push(.pw) },
                    onShowAppearance: { navigator.push(.appearance) }
                )
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .appearance:
                        AppearanceView(viewModel: SettingsVM(appState: appState))
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
        }
    }
}


#Preview {
    AppRootView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(AppState())
}
