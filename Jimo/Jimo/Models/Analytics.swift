//
//  Analytics.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/8/22.
//

import Firebase
import FirebaseAnalytics
import SwiftUI

#if DEBUG
private let enableAnalytics = false
#else
private let enableAnalytics = true
#endif

extension View {
    /// Mark the given view as a screen and track when it appears.
    func trackScreen(_ screen: Screen) -> some View {
        self.appear { Analytics.shared.currentScreen = screen }
    }

    /// Track the given sheet as a screen, screenAfterDismiss is necessary because the previous screen's isn't called when the sheet is dismissed.
    func trackSheet(_ screen: Screen, screenAfterDismiss: @escaping () -> Screen) -> some View {
        self
            .appear { Analytics.shared.currentScreen = screen }
            .disappear { Analytics.shared.currentScreen = screenAfterDismiss() }
    }
}

class Analytics {
    static let shared = Analytics()

    var ANALYTICS_ENABLED: Bool!
    var currentScreen: Screen? {
        didSet {
            guard currentScreen != oldValue else {
                return
            }
            if let screen = currentScreen {
                self.logScreen(screen)
            } else {
                self.logScreen(.unknown)
            }
        }
    }

    func initialize() {
        ANALYTICS_ENABLED = enableAnalytics
        print("ANALYTICS_ENABLED == \(String(describing: ANALYTICS_ENABLED))")
        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(ANALYTICS_ENABLED)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(ANALYTICS_ENABLED)
    }

    func logScreen(_ screen: Screen) {
        logEvent(
            AnalyticsEventScreenView,
            parameters: [AnalyticsParameterScreenName: screen.rawValue, AnalyticsParameterScreenClass: screen.rawValue]
        )
    }

    func logNotificationBellTap(badgePresent: Bool) {
        logEvent("tap_notification_bell", parameters: ["badge_present": badgePresent])
    }

    func logInviteContact() {
        logEvent("invite_contact", parameters: nil)
    }

    private func logEvent(_ name: String, parameters: [String: Any]?) {
        if ANALYTICS_ENABLED {
            FirebaseAnalytics.Analytics.logEvent(name, parameters: parameters)
        } else {
            print("event \(name) parameters \(String(describing: parameters))")
        }
    }
}
