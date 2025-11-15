import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }

    func sendNotification(title: String, body: String) {
        // Check if notifications are enabled in settings
        let notificationsEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") as? Bool ?? true
        guard notificationsEnabled else {
            print("Notifications disabled in settings, skipping: \(title)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            } else {
                print("Notification sent: \(title)")
            }
        }
    }
}
