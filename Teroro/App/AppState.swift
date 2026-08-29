import SwiftUI

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var isAppLoaded: Bool = false
    @Published var isAppAccountInitiated: Bool = false
    
    @Published var isShowPwTrial: Bool = false
    @Published var isShowPaywall: Bool = false
    
    @Published var alertData: AlertData?
    @Published var pendingDeepLink: DeepLinkDestination?
    
//    func presentPaywall() {
//        isShowPaywall = true
//    }
}

enum DeepLinkDestination: Equatable {
    case addTerm
    case editTerm(UUID)
}

struct AlertData: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

extension AppState {
    func showErrorAlert(_ message: String) {
        DispatchQueue.main.async {
            self.alertData = AlertData(title: "Error", message: message)
        }
    }

    func handleDeepLink(_ url: URL) {
        guard url.scheme == "teroro" else { return }

        // teroro://add, teroro://addTerm, teroro://new, teroro://term/add
        if url.host == "add" || url.host == "addTerm" || url.host == "new" || url.path == "/add" || url.path == "/new" {
            pendingDeepLink = .addTerm
            return
        }

        // teroro://term/<UUID>
        if url.host == "term" {
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if path == "add" || path == "new" {
                pendingDeepLink = .addTerm
            } else if let uuid = UUID(uuidString: path) {
                pendingDeepLink = .editTerm(uuid)
            }
            return
        }

        // teroro://edit/<UUID> or teroro://edit?id=<UUID>
        if url.host == "edit" {
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if let uuid = UUID(uuidString: path) {
                pendingDeepLink = .editTerm(uuid)
                return
            }
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let idString = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let uuid = UUID(uuidString: idString) {
                pendingDeepLink = .editTerm(uuid)
                return
            }
        }

        // Fallback: teroro://<UUID>
        if let host = url.host, let uuid = UUID(uuidString: host) {
            pendingDeepLink = .editTerm(uuid)
        }
    }
}
