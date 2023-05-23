//
//  FeedTabBody.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI

struct FeedTabBody: View {
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @EnvironmentObject var notificationFeedVM: NotificationFeedViewModel
    @EnvironmentObject var navigationState: NavigationState

    var notificationBellBadgePresent: Bool

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
        if appState.me != nil {
            Feed(onCreatePostTap: onCreatePostTap)
                // When swiping back from search users sometimes adds a black bar where keyboard would be
                // This fixes that
                .ignoresSafeArea(.keyboard, edges: .all)
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
                            navigationState.push(.notificationFeed)
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
