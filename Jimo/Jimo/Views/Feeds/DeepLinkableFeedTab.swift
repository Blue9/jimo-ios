//
//  DeepLinkableFeedTab.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/13/23.
//

import SwiftUI

struct DeepLinkableFeedTab: View {
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @ObservedObject var navigationState: NavigationState

    @ObservedObject var notificationsModel: NotificationBadgeModel
    @StateObject private var notificationFeedVM = NotificationFeedViewModel()

    var onCreatePostTap: () -> Void

    var showBadge: Bool {
        notificationsModel.unreadNotifications > 0 || notificationFeedVM.shouldRequestNotificationPermissions
    }

    var body: some View {
        Navigator(state: navigationState) {
            FeedTabBody(
                notificationBellBadgePresent: showBadge,
                onCreatePostTap: { globalViewState.createPostPresented = true }
            )
        }
        .onChange(of: deepLinkManager.navigationState.path) { path in
            print("navigation path updated to \(path)")
        }
        .environmentObject(appState)
        .environmentObject(globalViewState)
        .environmentObject(notificationFeedVM)
    }
}
