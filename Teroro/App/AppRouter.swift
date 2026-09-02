import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    enum Tab: Hashable {
        case terms
        case map
        case timer
        case profile
    }

    @Published var selectedTab: Tab = .terms
    @Published var termsPath = NavigationPath()
    @Published var profilePath = NavigationPath()
    @Published var path = NavigationPath()

    func push(_ route: AppRoute, tab: Tab? = nil) {
        if route == .onboarding || route == .onboardingPaywall {
            path.append(route)
            return
        }
        let activeTab = tab ?? selectedTab
        switch activeTab {
        case .terms:
            termsPath.append(route)
        case .profile:
            profilePath.append(route)
        default:
            path.append(route)
        }
    }

    func pop() {
        popBack(1, tab: nil)
    }

    func pop(tab: Tab?) {
        popBack(1, tab: tab)
    }

    func popBack(_ count: Int = 1, tab: Tab? = nil) {
        guard count > 0 else { return }
        let activeTab = tab ?? selectedTab
        switch activeTab {
        case .terms:
            let removeCount = min(count, termsPath.count)
            guard removeCount > 0 else { return }
            termsPath.removeLast(removeCount)
        case .profile:
            let removeCount = min(count, profilePath.count)
            guard removeCount > 0 else { return }
            profilePath.removeLast(removeCount)
        default:
            let removeCount = min(count, path.count)
            guard removeCount > 0 else { return }
            path.removeLast(removeCount)
        }
    }

    func popToRoot(tab: Tab? = nil) {
        if path.count > 0 {
            path.removeLast(path.count)
        }
        let activeTab = tab ?? selectedTab
        switch activeTab {
        case .terms:
            guard termsPath.count > 0 else { return }
            termsPath.removeLast(termsPath.count)
        case .profile:
            guard profilePath.count > 0 else { return }
            profilePath.removeLast(profilePath.count)
        default:
            break
        }
    }
}


enum AppRoute: Hashable {
    case onboarding
    case onboardingPaywall
    case addTerm
    case editTerm(UUID)
    case pastTerms
    case settings
    case appearance
    case privacyAndSecurity
    case pw
}
