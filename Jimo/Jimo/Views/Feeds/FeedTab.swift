//
//  FeedTab.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI

struct FeedTab: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @State private var showFeedback = false
    @State private var showInvite = false
    @State private var showNotifications = false
    
    @StateObject private var notificationFeedVM = NotificationFeedViewModel()
    
    var notificationBellBadgePresent: Bool {
        appState.unreadNotifications > 0
    }
    
    var onCreatePostTap: () -> ()

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
    }
    
    var body: some View {
        NavigationView {
            Feed(onCreatePostTap: onCreatePostTap)
                .background(
                    NavigationLink(destination: NotificationFeed(notificationFeedVM: notificationFeedVM)
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState), isActive: $showNotifications) {}
                )
                .background(
                    /// iOS 14.5 bug
                    /// https://developer.apple.com/forums/thread/677333
                    NavigationLink(destination: EmptyView()) {
                        EmptyView()
                    }
                )
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarColor(UIColor(Color("background")))
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showInvite.toggle() }) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .foregroundColor(Color("foreground"))
                        }
                        .sheet(isPresented: $showInvite) {
                            NavigationView {
                                InviteContactsView()
                                    .trackSheet(.inviteContacts, screenAfterDismiss: { .feedTab })
                            }
                            .environmentObject(appState)
                        }
                    }
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
                .trackScreen(.feedTab)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
