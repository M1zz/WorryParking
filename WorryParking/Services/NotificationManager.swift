import Foundation
import UserNotifications

/// Schedules "ready for pickup" reminders. The worry text itself is never put
/// in a notification — it stays parked (and private) until the user opens it.
enum NotificationManager {
    private static var center: UNUserNotificationCenter { .current() }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    static func scheduleExit(ticketID: UUID, spot: Int, at date: Date) async {
        var status = await authorizationStatus()
        if status == .notDetermined {
            _ = await requestAuthorization()
            status = await authorizationStatus()
        }
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "P\(spot) is ready for pickup")
        content.body = String(localized: "It's Worry Time. Give it \(AppConfig.worrySessionMinutes) focused minutes, then decide what to do with it.")
        content.sound = .default
        content.threadIdentifier = "worry-time"

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: ticketID.uuidString,
            content: content,
            trigger: trigger
        )

        center.removePendingNotificationRequests(withIdentifiers: [ticketID.uuidString])
        try? await center.add(request)
    }

    static func cancel(ticketID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [ticketID.uuidString])
        center.removeDeliveredNotifications(withIdentifiers: [ticketID.uuidString])
    }
}
