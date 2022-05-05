//
//  Analytics.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/8/22.
//

import SwiftUI
import Firebase
import FirebaseAnalytics

#if DEBUG
fileprivate let enableAnalytics = false
#else
fileprivate let enableAnalytics = true
#endif

extension View {
    /// Mark the given view as a screen and track when it appears.
    func trackScreen(_ screen: Screen) -> some View {
        self.appear { Analytics.currentScreen = screen }
    }
    
    /// Track the given sheet as a screen, screenAfterDismiss is necessary because the previous screen's isn't called when the sheet is dismissed.
    func trackSheet(_ screen: Screen, screenAfterDismiss: @escaping () -> Screen) -> some View {
        self
            .appear { Analytics.currentScreen = screen }
            .disappear { Analytics.currentScreen = screenAfterDismiss() }
    }
}

class Analytics {
    static var currentScreen: Screen? {
        didSet {
            guard currentScreen != oldValue else {
                return
            }
            Analytics.track(.screenView, parameters: [
                AnalyticsParameterScreenName: (currentScreen ?? .unknown).rawValue,
                AnalyticsParameterScreenClass: (currentScreen ?? .unknown).rawValue
            ])
        }
    }
    
    static func initialize() {
        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(enableAnalytics)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(enableAnalytics)
    }

    /// Used to track a given event.
    /// - Parameters:
    ///   - event: The type of analytic we want to track.
    ///   - parameters: Any additional properties we want to associate with the event.
    static func track(_ event: AnalyticsName, parameters: [String: Any?]? = nil) {
        guard enableAnalytics else {
            print("event \(event.rawValue) parameters \(String(describing: parameters))")
            return
        }
        FirebaseAnalytics.Analytics.logEvent(event.rawValue, parameters: parameters?.compactMapValues { $0 })
    }
}

/// Each analytic event is stored here
enum AnalyticsName: RawRepresentable, Equatable {
    typealias RawValue = String

    var rawValue: RawValue {
        // hard code for firebase screen view event
        if self == .screenView {
            return AnalyticsEventScreenView
        }

        var name = "\(self)".snakeized
        if let index = name.firstIndex(of: "(") {
            name = name.prefix(upTo: index).lowercased()
        }
        return name
    }

    init?(rawValue: String) {
        return nil
    }

    // MARK: Push Notifications

    /// Track when new screen is viewed
    case screenView

    /// Track when notification bell tapped
    case tapNotificationBell

    /// Track when contact was invited to app
    case inviteContact

    /// Share sheet presented
    case shareSheetPresented
    /// Share sheet cancelled
    case shareSheetCancelled
    /// Share sheet completed
    case shareSheetCompleted
}
