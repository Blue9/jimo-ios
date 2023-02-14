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

    /// Track when new screen is viewed
    case screenView

    /// Onboarding
    case onboardingCitySelected

    /// Track when notification bell tapped
    case tapNotificationBell

    /// Share profile
    case shareProfilePresented
    case shareProfileCancelled
    case shareProfileCompleted

    /// Share post
    case sharePostPresented
    case sharePostCancelled
    case sharePostCompleted

    /// Post actions
    case postPlaceNameTap
    case postCreated
    case postUpdated
    case postDeleted
    case postLiked
    case postUnliked

    /// Comment actions
    case commentCreated
    case commentDeleted

    /// Profile actions
    case userFollowed
    case userUnfollowed
    case profileNewPostTapped
    case shareMyProfileTapped

    /// Map actions
    case mapCreatePostTapped
    case mapSavePlace
    case mapPinTapped
    case mapSearchResultTapped

    /// Notifications
    case notificationFeedEnableTap
    case notificationFeedShareTap
    case notificationPermissionsAllowed
    case notificationPermissionsDenied

    /// Permissions
    case locationPermissionsAllowed
    case locationPermissionsDenied
    case contactsPermissionsAllowed
    case contactsPermissionsDenied

    /// Misc
    case signInAnonymous
    case guestAccountSignUpTap
    case updateAppVersionTapped
}
