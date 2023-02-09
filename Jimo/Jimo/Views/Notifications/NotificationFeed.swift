//
//  NotificationFeed.swift
//  Jimo
//
//  Created by Jeff Rohlman on 3/2/21.
//

import SwiftUI

struct NotificationFeed: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState

    @ObservedObject var notificationFeedVM: NotificationFeedViewModel
    @State private var showShareProfileOverlay = false

    var body: some View {
        RefreshableScrollView(spacing: 10) {
            if notificationFeedVM.shouldRequestNotificationPermissions {
                EnableNotificationsButton()
            }

            ForEach(notificationFeedVM.feedItems) { item in
                NotificationFeedItem(item: item)
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
                    .padding(.horizontal, 10)
            }

            HStack {
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .padding(3)
                    .frame(width: 40, height: 40, alignment: .center)
                    .cornerRadius(20)
                    .padding(.trailing, 5)
                VStack(alignment: .leading) {
                    Text("Welcome! Jimo is more fun with friends. If you'd like, tap here to share your profile.")
                }
                .font(.system(size: 14))
                Spacer()
            }.onTapGesture {
                Analytics.track(.notificationFeedShareTap)
                self.showShareProfileOverlay = true
            }.padding(.horizontal, 10)
        } onRefresh: { onFinish in
            notificationFeedVM.refreshFeed(appState: appState, viewState: globalViewState, onFinish: onFinish)
        } onLoadMore: {
            notificationFeedVM.loadMoreNotifications(appState: appState, viewState: globalViewState)
        }
        .sheet(isPresented: $showShareProfileOverlay) {
            if let me = appState.me {
                ActivityView(shareAction: .profile(me), isPresented: $showShareProfileOverlay)
            } else {
                // This should never happen but it probably will because nothing ever makes sense
            }
        }
        .foregroundColor(Color("foreground"))
        .background(Color("background").edgesIgnoringSafeArea(.all))
        .onAppear {
            notificationFeedVM.onAppear(appState: appState, viewState: globalViewState)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(Color("background")))
        .navigationTitle(Text("Notifications"))
        .onChange(of: notificationFeedVM.loading) { loading in
            if !loading {
                appState.notificationsModel.unreadNotifications = 0
            }
        }
        .trackScreen(.notificationFeed)
    }
}

private struct NotificationFeedItem: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState

    @State private var relativeTime: String = ""

    let item: NotificationItem
    let defaultProfileImage: Image = Image(systemName: "person.crop.circle")

    var user: PublicUser {
        item.user
    }

    @ViewBuilder var profilePicture: some View {
        URLImage(url: user.profilePictureUrl, loading: defaultProfileImage)
            .frame(width: 40, height: 40, alignment: .center)
            .font(Font.title.weight(.ultraLight))
            .foregroundColor(.gray)
            .background(Color.white)
            .cornerRadius(50)
            .padding(.trailing, 5)
    }

    @ViewBuilder var postPreview: some View {
        if let url = item.post?.imageUrl {
            URLImage(url: url)
                .scaledToFill()
                .frame(width: 50, height: 50, alignment: .center)
                .clipped()
                .padding(.trailing)
        }
    }

    @ViewBuilder var destinationView: some View {
        if item.type == ItemType.like || item.type == ItemType.save {
            if let post = item.post {
                ViewPost(initialPost: post)
            }
        } else if item.type == ItemType.comment {
            if let post = item.post {
                ViewPost(initialPost: post, highlightedComment: item.comment)
            }
        } else {
            ProfileScreen(initialUser: item.user)
        }
    }

    var body: some View {
        NavigationLink {
            destinationView
        } label: {
            HStack {
                NavigationLink {
                    ProfileScreen(initialUser: user)
                } label: {
                    profilePicture
                }

                VStack(alignment: .leading) {
                    switch item.type {
                    case .follow:
                        Text(item.user.username + " started following you")
                    case .like:
                        Text(item.user.username + " likes your post")
                    case .save:
                        Text(item.user.username + " saved your post")
                    case .comment:
                        Text(item.user.username + " commented on your post")
                    case .unknown:
                        EmptyView()
                    }

                    Text(relativeTime)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .onAppear {
                            if relativeTime == "" {
                                relativeTime = appState.relativeTime(for: item.createdAt)
                            }
                        }
                }
                .font(.system(size: 14))

                Spacer()

                postPreview.cornerRadius(2)
            }
        }
        .buttonStyle(NoButtonStyle())
    }
}

private struct EnableNotificationsButton: View {
    var body: some View {
        Button(action: {
            Analytics.track(.notificationFeedEnableTap)
            PermissionManager.shared.requestNotifications()
        }) {
            Text("Tap to enable push notifications")
                .padding(10)
                .font(.system(size: 15))
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
                .foregroundColor(.white)
                .frame(height: 50)
        }
        .padding(.horizontal, 20)
    }
}
