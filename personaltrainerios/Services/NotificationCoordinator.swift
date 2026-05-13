import Foundation
import UserNotifications
import UIKit

/// Owns notification delegate duties — handles taps and translates them into
/// in-app routing intents that views observe.
///
/// We publish the tapped route via UserDefaults + NotificationCenter so the
/// SwiftUI layer can react regardless of which view is currently mounted.
final class NotificationCoordinator: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationCoordinator()
    static let didTapNotification = Notification.Name("didTapNotification")
    static let pendingRouteKey = "pendingNotificationRoute"

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Show notifications even when the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    /// User tapped a notification — extract the route and broadcast it.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if let routeValue = response.notification.request.content.userInfo[NotificationManager.routeKey] as? String {
            UserDefaults.standard.set(routeValue, forKey: Self.pendingRouteKey)
            NotificationCenter.default.post(name: Self.didTapNotification, object: routeValue)
        }
        completionHandler()
    }

    /// Pull the route from UserDefaults if one was stashed before the SwiftUI views mounted.
    static func consumePendingRoute() -> NotificationManager.Route? {
        guard let raw = UserDefaults.standard.string(forKey: pendingRouteKey),
              let route = NotificationManager.Route(rawValue: raw) else { return nil }
        UserDefaults.standard.removeObject(forKey: pendingRouteKey)
        return route
    }
}
