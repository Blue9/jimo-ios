//
//  NotificationFeed.swift
//  Jimo
//
//  Created by Jeff Rohlman on 3/2/21.
//

import SwiftUI
import ASCollectionView

struct NotificationFeed: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @ObservedObject var notificationFeedVM: NotificationFeedViewModel
    
    @State private var initialized = false
    
    var body: some View {
        ASCollectionView {
            ASCollectionViewSection(id: 0, data: notificationFeedVM.feedItems) { item, _ in
                NotificationFeedItem(item: item)
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
                    .padding(.horizontal, 10)
                    .frame(width: UIScreen.main.bounds.width)
                    .fixedSize()
                Divider()
                    .padding(.horizontal, 10)
                    .hidden()
            }
            .sectionFooter {
                VStack {
                    Divider()
                    
                    ProgressView()
                        .opacity(notificationFeedVM.loading ? 1 : 0)
                    Text("You've reached the end!")
                        .font(.system(size: 15))
                }
            }
        }
        .alwaysBounceVertical()
        .shouldScrollToAvoidKeyboard(false)
        .layout {
            .list(itemSize: .absolute(50))
        }
        .onPullToRefresh { onFinish in
            notificationFeedVM.refreshFeed(appState: appState, viewState: globalViewState, onFinish: onFinish)
        }
        .onReachedBoundary { boundary in
            if boundary == .bottom {
                notificationFeedVM.loadMoreNotifications(appState: appState, viewState: globalViewState)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .all)
        .foregroundColor(Color("foreground"))
        .background(Color("background").edgesIgnoringSafeArea(.all))
        .onAppear {
            if !initialized {
                notificationFeedVM.refreshFeed(appState: appState, viewState: globalViewState)
                initialized = true
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(Color("background")))
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                NavTitle("Notifications")
            }
        })
        .onChange(of: notificationFeedVM.loading) { loading in
            if !loading {
                appState.unreadNotifications = 0
            }
        }
        .trackScreen(.notificationFeed)
    }
}

fileprivate struct NotificationFeedItem: View {
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
        NavigationLink(destination: destinationView) {
            HStack {
                NavigationLink(destination: ProfileScreen(initialUser: user)) {
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
