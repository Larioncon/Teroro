import Foundation
import UserNotifications

actor NotificationService {
    static let shared = NotificationService()

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .notDetermined:
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        default:
            break
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleReminder(termID: UUID, title: String, termDate: Date, reminderDate: Date) async {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = Self.reminderBody(for: termDate)
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: termID.uuidString,
            content: content,
            trigger: trigger
        )

        await cancelReminder(termID: termID)
        try? await center.add(request)
    }

    func cancelReminder(termID: UUID) async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [termID.uuidString])
    }

    func schedulePomodoroNotification(after seconds: Int) async {
        guard seconds > 0 else { return }
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Таймер завершено!"
        content.body = "Вітаємо! Ви успішно завершили сесію фокусу. Час трохи відпочити!"
        content.sound = .default

        // Use absolute date for more reliability
        let fireDate = Date().addingTimeInterval(TimeInterval(seconds))
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "pomodoro_timer",
            content: content,
            trigger: trigger
        )

        do {
            // Remove both pending and already shown ones for this ID
            center.removePendingNotificationRequests(withIdentifiers: ["pomodoro_timer"])
            center.removeDeliveredNotifications(withIdentifiers: ["pomodoro_timer"])
            
            try await center.add(request)
            print("--- Pomodoro notification scheduled for \(fireDate) (in \(seconds)s)")
        } catch {
            print("--- Failed to schedule Pomodoro notification: \(error)")
        }
    }

    func cancelPomodoroNotification() async {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["pomodoro_timer"])
    }

    private static func reminderBody(for termDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Термін: \(formatter.string(from: termDate))"
    }
}
