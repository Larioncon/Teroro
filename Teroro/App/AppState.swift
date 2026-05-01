import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var isAppLoaded: Bool = false
    @Published var isAppAccountInitiated: Bool = false
    
    @Published var isShowOnbPw: Bool = false
    @Published var isShowPwExt: Bool = false
    @Published var isShowPwTrial: Bool = false
    @Published var isShowPaywall: Bool = false
    @Published var alertData: AlertData?
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
}
