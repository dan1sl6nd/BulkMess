import Foundation
import UserNotifications
import CoreData
import SwiftUI

class NotificationCenterHandler: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    private let persistenceController: PersistenceController
    init(persistenceController: PersistenceController) {
        self.persistenceController = persistenceController
        super.init()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let notificationId = response.notification.request.identifier
        print("📱 Received notification response: \(response.actionIdentifier) for \(notificationId)")
        completionHandler()
    }
}

