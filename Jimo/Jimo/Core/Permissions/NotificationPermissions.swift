//
//  Notifications.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/27/22.
//

import SwiftUI

extension PermissionManager {
    func requestNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .denied {
                DispatchQueue.main.async {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, completionHandler: { (_) in })
                }
            } else if settings.authorizationStatus != .authorized {
                UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .badge, .sound],
                    completionHandler: { (success, _) in
                        Analytics.track(success ? .notificationPermissionsAllowed : .notificationPermissionsDenied)
                    })
            }
        }
    }

    func getNotificationAuthStatus(callback: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            callback(settings.authorizationStatus)
        }
    }
}
