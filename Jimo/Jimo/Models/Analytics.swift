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
            Analytics.track(.screenView, properties: [
                AnalyticsParameterScreenName: (currentScreen ?? .unknown).rawValue,
                AnalyticsParameterScreenClass: (currentScreen ?? .unknown).rawValue
            ])
        }
    }
    
    func initialize() {
        ANALYTICS_ENABLED = enableAnalytics
        print("ANALYTICS_ENABLED == \(String(describing: ANALYTICS_ENABLED))")
        FirebaseAnalytics.Analytics.setAnalyticsCollectionEnabled(ANALYTICS_ENABLED)
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(ANALYTICS_ENABLED)
    }

    /// Used to track a given event.
    /// - Parameters:
    ///   - event: The type of analytic we want to track.
    ///   - properties: Any additional properties we want to associate with the event.
    ///   - key: The key to increment and track on. Shortcut used to track how many times a given event has been hit prior. While we could just extrapolate this information from the analytics, this is useful in allowing us to continue tracking between installations. A rare case but worth tracking since it's so cheap.
    static func track(_ event: AnalyticsName, properties: [String: Any?]? = nil, key: AnalyticsKey? = nil) {
        guard let key = key else {
            FirebaseAnalytics.Analytics.logEvent(event.rawValue, parameters: properties?.compactMapValues { $0 })
            return
        }

        let attempt = UserDefaults.standard.integer(forKey: key.rawValue) + 1
        FirebaseAnalytics.Analytics.logEvent(event.rawValue, parameters: join(properties?.compactMapValues { $0 }, [
            "attempts": attempt
        ]))
        UserDefaults.standard.set(attempt, forKey: key.rawValue)
    }

    /**
     Consolidate multiple nullable dictionaries into a single dictionary.
     */
    private static func join(_ props: [String: Any]?...) -> [String: Any] {
        var total: [String: Any] = [:]
        for prop in props {
            if let prop = prop {
                total = total.merging(prop, uniquingKeysWith: { first, _ in first })
            }
        }
        return total
    }
}

/// UserDefaults key for tracking number of attempts per
/// TODO currently unused as we do not track numbers
enum AnalyticsKey {
    typealias RawValue = String

    var rawValue: RawValue {
        var name = "\(self)".snakeized
        if let index = name.firstIndex(of: "(") {
            name = name.prefix(upTo: index).lowercased()
        }
        return "ANALYTICS_" + name.uppercased()
    }

    init?(rawValue: String) {
        return nil
    }

    case notificationsPrompt
    case locationsPrompt
    case contactsPrompt
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
