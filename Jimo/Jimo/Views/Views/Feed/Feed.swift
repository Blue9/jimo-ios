//
//  Feed.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI
import Combine


class FeedViewModel: ObservableObject {
    let nc = NotificationCenter.default
    
    @Published var feed: [Post] = []
    @Published var initialized = false
    @Published var loadingMorePosts = false
    @Published var navigation: PostDestination?
    
    var cursor: String?
    
    var refreshFeedCancellable: AnyCancellable?
    var listenToFeedCancellable: AnyCancellable?
    
    init() {
        nc.addObserver(self, selector: #selector(postCreated), name: PostPublisher.postCreated, object: nil)
        nc.addObserver(self, selector: #selector(postUpdated), name: PostPublisher.postUpdated, object: nil)
        nc.addObserver(self, selector: #selector(postLiked), name: PostPublisher.postLiked, object: nil)
        nc.addObserver(self, selector: #selector(postDeleted), name: PostPublisher.postDeleted, object: nil)
    }
    
    @objc private func postCreated(notification: Notification) {
        let post = notification.object as! Post
        feed.insert(post, at: 0)
    }
    
    @objc private func postUpdated(notification: Notification) {
        let post = notification.object as! Post
        if let i = feed.indices.first(where: { feed[$0].postId == post.postId }) {
            feed[i] = post
        }
    }
    
    @objc private func postLiked(notification: Notification) {
        let like = notification.object as! PostLikePayload
        let postIndex = feed.indices.first(where: { feed[$0].postId == like.postId })
        if let i = postIndex {
            feed[i].likeCount = like.likeCount
            feed[i].liked = like.liked
        }
    }
    
    @objc private func postDeleted(notification: Notification) {
        let postId = notification.object as! PostId
        feed.removeAll(where: { $0.postId == postId })
    }
    
    func refreshFeed(appState: AppState, globalViewState: GlobalViewState, onFinish: OnFinish? = nil) {
        refreshFeedCancellable = appState.refreshFeed()
            .sink(receiveCompletion: { [weak self] completion in
                onFinish?()
                guard let self = self else {
                    return
                }
                if !self.initialized {
                    self.initialized = true
                }
                if case let .failure(error) = completion {
                    print("Error when refreshing feed", error)
                    globalViewState.setError("Could not refresh feed")
                }
            }, receiveValue: { [weak self] feed in
                self?.feed = feed.posts
                self?.cursor = feed.cursor
                self?.initialized = true
            })
    }
    
    func loadMorePosts(appState: AppState, globalViewState: GlobalViewState) {
        guard let cursor = cursor, !loadingMorePosts else {
            return
        }
        loadingMorePosts = true
        print("Loading more posts")
        refreshFeedCancellable = appState.loadMoreFeedItems(cursor: cursor)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else {
                    return
                }
                self.loadingMorePosts = false
                if case let .failure(error) = completion {
                    print("Error when loading more posts", error)
                    globalViewState.setError("Could not load more posts")
                }
            }, receiveValue: { [weak self] nextPage in
                self?.feed.append(contentsOf: nextPage.posts)
                self?.cursor = nextPage.cursor
            })
    }
}

struct FeedBody: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @StateObject var feedViewModel = FeedViewModel()
    
    var onCreatePostTap: () -> ()
    
    private func loadMore() {
        if feedViewModel.loadingMorePosts {
            return
        }
        feedViewModel.loadMorePosts(appState: appState, globalViewState: viewState)
    }
    
    var initializedFeed: some View {
        RefreshableScrollView {
            LazyVStack {
                ForEach(feedViewModel.feed) { post in
                    FeedItem(post: post)
                        .frame(width: UIScreen.main.bounds.width)
                        .fixedSize(horizontal: true, vertical: true)
                }
                Color.clear
                    .appear {
                        feedViewModel.loadMorePosts(appState: appState, globalViewState: viewState)
                    }
            }
        } onRefresh: { onFinish in
            feedViewModel.refreshFeed(appState: appState, globalViewState: viewState, onFinish: onFinish)
        }
    }
    
    var body: some View {
        Group {
            if !feedViewModel.initialized {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        feedViewModel.refreshFeed(appState: appState, globalViewState: viewState)
                    }
            } else if feedViewModel.feed.isEmpty {
                Button(action: {
                    onCreatePostTap()
                }) {
                    HStack {
                        Image("postIcon")
                            .font(.system(size: 15))
                        Text("Save a place to get started")
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            } else {
                initializedFeed
            }
        }
        .background(Color("background"))
    }
}

struct Feed: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @State private var showFeedback = false
    @State private var showInvite = false
    @State private var showNotifications = false
    
    @StateObject private var notificationFeedVM = NotificationFeedVM()
    
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
            FeedBody(onCreatePostTap: onCreatePostTap)
                .background(
                    NavigationLink(destination: NotificationFeed(notificationFeedVM: notificationFeedVM)
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState), isActive: $showNotifications) {}
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
                            Analytics.shared.logNotificationBellTap(badgePresent: notificationBellBadgePresent)
                            self.showNotifications.toggle()
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
