//
//  FeedTab.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI

struct FeedTab: View {
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @ObservedObject var notificationsModel: NotificationBadgeModel

    @State private var showFeedback = false
    @State private var showInvite = false
    @State private var showNotifications = false

    @StateObject private var notificationFeedVM = NotificationFeedViewModel()

    var notificationBellBadgePresent: Bool {
        notificationsModel.unreadNotifications > 0 || notificationFeedVM.shouldRequestNotificationPermissions
    }

    var onCreatePostTap: () -> Void

    var notificationFeedIcon: some View {
        ZStack(alignment: .topTrailing) {
            Image(systemName: "bell")
                .foregroundColor(Color("foreground"))
            if notificationBellBadgePresent {
                Circle()
                    .fill()
                    .frame(width: 10, height: 10)
                    .foregroundColor(Color(UIColor.systemRed))
                    .offset(x: -1)
            }
        }
        .onAppear {
            PermissionManager.shared.getNotificationAuthStatus { status in
                DispatchQueue.main.async {
                    notificationFeedVM.shouldRequestNotificationPermissions = status != .authorized
                }
            }
        }
        .onChange(of: scenePhase) { _ in
            PermissionManager.shared.getNotificationAuthStatus { status in
                DispatchQueue.main.async {
                    notificationFeedVM.shouldRequestNotificationPermissions = status != .authorized
                }
            }
        }
    }

    var body: some View {
        Navigator {
            if appState.me != nil {
                Feed(onCreatePostTap: onCreatePostTap)
                    .navDestination(isPresented: $showNotifications) {
                        NotificationFeed(notificationFeedVM: notificationFeedVM)
                            .environmentObject(appState)
                            .environmentObject(globalViewState)
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarColor(UIColor(Color("background")))
                    .toolbar(content: {
                        ToolbarItem(placement: .principal) {
                            Image("logo")
                                .renderingMode(.template)
                                .resizable()
                                .foregroundColor(Color("foreground"))
                                .scaledToFit()
                                .frame(width: 50)
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                Analytics.track(.tapNotificationBell, parameters: ["badge_present": notificationBellBadgePresent])
                                self.showNotifications = true
                            }) {
                                notificationFeedIcon
                            }
                        }
                    })
            } else {
                AnonymousFeedPlaceholder()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar(content: {
                        ToolbarItem(placement: .principal) {
                            Image("logo")
                                .renderingMode(.template)
                                .resizable()
                                .foregroundColor(Color("foreground"))
                                .scaledToFit()
                                .frame(width: 50)
                        }
                    })
                    .redacted(reason: .placeholder)
                    .overlay(SignUpPush())
            }
        }
    }
}

private struct SignUpPush: View {
    @EnvironmentObject var viewState: GlobalViewState

    var body: some View {
        ZStack {
            Color("background").opacity(0.4)

            Button {
                viewState.showSignUpPage(.feed)
            } label: {
                Text("Sign up to view your feed")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
    }
}
