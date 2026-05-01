import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        popBack(1)
    }

    func popToRoot() {
        guard path.count > 0 else { return }
        path.removeLast(path.count)
    }

    func popBack(_ count: Int) {
        guard count > 0 else { return }
        let removeCount = min(count, path.count)
        guard removeCount > 0 else { return }
        path.removeLast(removeCount)
    }
}


enum AppRoute: Hashable {
    case onboarding
    case addTerm
    case editTerm(UUID)
    case pastTerms
    case settings
}
