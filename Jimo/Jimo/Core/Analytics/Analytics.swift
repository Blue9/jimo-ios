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
fileprivate let ANALYTICS_ENABLED = false
#else
fileprivate let ANALYTICS_ENABLED = true
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
        print("ANALYTICS_ENABLED == \(ANALYTICS_ENABLED)")
        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(ANALYTICS_ENABLED)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(ANALYTICS_ENABLED)
    }

    /// Used to track a given event.
    /// - Parameters:
    ///   - event: The type of analytic we want to track.
    ///   - parameters: Any additional properties we want to associate with the event.
    static func track(_ event: AnalyticsName, parameters: [String: Any?]? = nil) {
        guard ANALYTICS_ENABLED else {
            print("event \(event.eventName) parameters \(String(describing: parameters))")
            return
        }
        FirebaseAnalytics.Analytics.logEvent(event.eventName, parameters: parameters?.compactMapValues { $0 })
    }
}

/// Each analytic event is stored here
enum AnalyticsName: Equatable {
    typealias RawValue = String

    var eventName: String {
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
    
    // MARK: Push Notifications

    /// Track when new screen is viewed
    case screenView

    /// Track when notification bell tapped
    case tapNotificationBell

    /// Track when contact was invited to app
    case inviteContact

    /// Share sheet presented
    case shareProfilePresented
    /// Share sheet cancelled
    case shareProfileCancelled
    /// Share sheet completed
    case shareProfileCompleted
    
    /// Share sheet presented
    case sharePostPresented
    /// Share sheet cancelled
    case sharePostCancelled
    /// Share sheet completed
    case sharePostCompleted
    
    case postCreated
    case postUpdated
    case postDeleted
    
    case postLiked
    case postUnliked
    
    case commentCreated
    case commentDeleted
    
    case postSaved
    case postUnsaved
    
    case userFollowed
    case userUnfollowed
}