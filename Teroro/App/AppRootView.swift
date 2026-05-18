import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var navigator = AppRouter()
    @StateObject private var authVM = AuthVM()
    @StateObject private var homeVM: HomeVM
    @StateObject private var mapVM = TermsMapVM()
    @StateObject private var pomodoroVM = PomodoroVM()
    @AppStorage("appAppearance") private var appearanceRawValue: Int = AppAppearance.system.rawValue

    init() {
        _homeVM = StateObject(wrappedValue: HomeVM())
    }

    private var preferredColorScheme: ColorScheme? {
        (AppAppearance(rawValue: appearanceRawValue) ?? .system).preferredColorScheme
    }

    var body: some View {
        Group {
            if authVM.isLoggedIn {
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
                                SettingsView(viewModel: SettingsVM())
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

                    NavigationStack {
                        SettingsView(viewModel: SettingsVM())
                    }
                    .tabItem {
                        Label("Профіль", systemImage: "person.crop.circle")
                    }
                }
            } else {
                AuthScreen(viewModel: authVM)
            }
        }
        .preferredColorScheme(preferredColorScheme)
        .fullScreenCover(isPresented: $appState.isShowPaywall) {
            PaywallScreen()
                .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $appState.isShowPwTrial) {
            PaywallScreen()
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

#Preview {
    AppRootView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(AppState())
}
