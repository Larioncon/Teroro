import SwiftUI

struct AppRootView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appState: AppState
    @StateObject private var navigator = AppRouter()
    @StateObject private var homeVM: HomeVM
    @StateObject private var mapVM = TermsMapVM()
    @StateObject private var pomodoroVM = PomodoroVM()
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    init() {

        _homeVM = StateObject(wrappedValue: HomeVM(container: PersistenceController.shared.container))
    }

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
                            viewModel: AddTermVM(context: viewContext),
                            title: "Новий термін",
                            onSave: {
                                homeVM.fetchTerms()
                                navigator.pop()
                            },
                            onCancel: navigator.pop
                        )
                    case .editTerm(let id):
                        TermFormView(
                            viewModel: EditTermVM(termID: id, context: viewContext),
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

            TermsMapView(viewModel: mapVM, terms: homeVM.terms)
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
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .fullScreenCover(isPresented: $appState.isShowPaywall) {
            PaywallScreen()
                .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $appState.isShowPwTrial) {
            PaywallScreen()
                .environmentObject(appState)
        }
    }
}

#Preview {
    AppRootView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(AppState())
}
