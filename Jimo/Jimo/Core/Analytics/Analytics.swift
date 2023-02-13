//
//  Analytics.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/8/22.
//

import SwiftUI
import Firebase
import FirebaseAnalytics

extension View {
    /// Mark the given view as a screen and track when it appears.
    func trackScreen(_ screen: Screen) -> some View {
        self.onAppear { Analytics.trackScreen(screen) }
    }

    /// Track the given sheet as a screen, screenAfterDismiss is necessary
    /// because the previous screen's appear isn't called when the sheet is dismissed.
    func trackSheet(_ screen: Screen, screenAfterDismiss: @escaping () -> Screen?) -> some View {
        self
            .onAppear { Analytics.trackScreen(screen) }
            .onDisappear {
                if let screen = screenAfterDismiss() {
                    Analytics.trackScreen(screen)
                }
            }
    }
}

class Analytics {
    #if DEBUG
    static let analyticsEnabled = false
    #else
    static let analyticsEnabled = true
    #endif

    private(set) static var currentScreen: Screen?

    static func initialize() {
        print("ANALYTICS_ENABLED == \(analyticsEnabled)")
        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(analyticsEnabled)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(analyticsEnabled)
    }

    static func trackScreen(_ screen: Screen) {
        if screen != self.currentScreen {
            Analytics.track(.screenView, parameters: [
                AnalyticsParameterScreenName: (screen).rawValue,
                AnalyticsParameterScreenClass: (screen).rawValue
            ])
            self.currentScreen = screen
        }
    }

    /// Used to track a given event.
    /// - Parameters:
    ///   - event: The type of analytic we want to track.
    ///   - parameters: Any additional properties we want to associate with the event.
    static func track(_ event: AnalyticsName, parameters: [String: Any?]? = nil) {
        var finalParameters = parameters ?? [:]
        if let user = Auth.auth().currentUser {
            finalParameters["isAnonymous"] = user.isAnonymous
        }
        guard analyticsEnabled else {
            print("event \(event.eventName) parameters \(String(describing: finalParameters))")
            return
        }
        FirebaseAnalytics.Analytics.logEvent(
            event.eventName,
            parameters: finalParameters.compactMapValues { $0 }
        )
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

    case signInAnonymous

    /// Track when new screen is viewed
    case screenView

    /// Track when notification bell tapped
    case tapNotificationBell

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

    case postPlaceNameTap
    case postCreated
    case postUpdated
    case postDeleted

    case postLiked
    case postUnliked

    case commentCreated
    case commentDeleted

    // Profile action button events
    case userFollowed
    case userUnfollowed
    case feedFindFriendsTapped
    case profileNewPostTapped

    // Notifications
    case notificationFeedEnableTap
    case notificationFeedShareTap
    case notificationPermissionsAllowed
    case notificationPermissionsDenied

    case locationPermissionsAllowed
    case locationPermissionsDenied

    case contactsPermissionsAllowed
    case contactsPermissionsDenied

    case mapCreatePostTapped
    case mapSavePlace
    case mapPinTapped
    case mapSearchResultTapped

    case updateAppVersionTapped
    case guestAccountSignUpTap
}
