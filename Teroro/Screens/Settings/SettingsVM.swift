import SwiftUI
import UserNotifications
import UIKit

@MainActor
final class SettingsVM: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false

    let contactURL = URL(string: "https://sites.google.com/view/0047coslw")!

    @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var statusFlipRotation: Double = 0

    var isNotificationsEnabled: Bool {
        notificationStatus == .authorized || notificationStatus == .provisional
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

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
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
}
