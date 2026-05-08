import SwiftUI
import UserNotifications
import UIKit

@MainActor
final class SettingsVM: ObservableObject {
    @AppStorage("appAppearance") private var appearanceRawValue: Int = AppAppearance.system.rawValue

    var appearance: AppAppearance {
        get { AppAppearance(rawValue: appearanceRawValue) ?? .system }
        set { appearanceRawValue = newValue.rawValue }
    }

    private let authService: FirebaseAuthService

    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var statusFlipRotation: Double = 0
    @Published var signOutErrorMessage: String?

    var isNotificationsEnabled: Bool {
        notificationStatus == .authorized || notificationStatus == .provisional
    }

    init(authService: FirebaseAuthService = .shared) {
        self.authService = authService
        migrateLegacyThemeIfNeeded()
    }

    // MARK: - View Events

    func onAppear() {
        Task { await refreshNotificationStatus(animated: false) }
    }

    func onScenePhaseChanged(_ newPhase: ScenePhase) {
        guard newPhase == .active else { return }
        Task { await refreshNotificationStatus(animated: true) }
    }

    // MARK: - UI State

    var isNotificationStatusIconShowingEnabled: Bool {
        // When the icon flips, keep the "front" face consistent through the rotation.
        let angle = statusFlipRotation.truncatingRemainder(dividingBy: 360)
        return (angle < 90) || (angle > 270)
    }

    var contactURL: URL {
        URL(string: AppConstants.contactUsLink) ?? URL(string: "https://sites.google.com/view/0047coslw")!
    }

    var termsURL: URL? {
        URL(string: AppConstants.termsOfUseLink)
    }

    var privacyURL: URL? {
        URL(string: AppConstants.privacyPolicyLink)
    }

    var appStoreURL: URL? {
        URL(string: AppConstants.appStoreLink)
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func openTermsOfUse() {
        guard let url = termsURL else { return }
        UIApplication.shared.open(url)
    }

    func openPrivacyPolicy() {
        guard let url = privacyURL else { return }
        UIApplication.shared.open(url)
    }

    func openFeedback() {
        // Prefer email, fallback to contact page.
        let email = AppConstants.contactUsEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if !email.isEmpty,
           let url = URL(string: "mailto:\(email)"),
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            return
        }

        UIApplication.shared.open(contactURL)
    }

    func signOut() {
        signOutErrorMessage = nil
        do {
            try authService.signOut()
        } catch {
            signOutErrorMessage = error.localizedDescription
        }
    }

    func refreshNotificationStatus(animated: Bool) async {
        let status = await UNUserNotificationCenter.current()
            .notificationSettings()
            .authorizationStatus

        let targetRotation = (status == .authorized || status == .provisional) ? 0.0 : 180.0

        if animated {
            withAnimation(.easeInOut(duration: 0.35)) {
                notificationStatus = status
                statusFlipRotation = targetRotation
            }
        } else {
            notificationStatus = status
            statusFlipRotation = targetRotation
        }
    }

    // MARK: - Private

    private func migrateLegacyThemeIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: "appAppearance") == nil else { return }
        guard defaults.object(forKey: "isDarkMode") != nil else { return }

        let wasDark = defaults.bool(forKey: "isDarkMode")
        appearanceRawValue = (wasDark ? AppAppearance.dark : AppAppearance.light).rawValue
    }
}
