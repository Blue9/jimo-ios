//
//  Feed.swift
//  Jimo
//
//  Created by Gautam Mekkat on 7/26/22.
//

import SwiftUI
import Combine

private enum FeedType: Equatable {
    case following, forYou
}

struct Feed: View {
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @StateObject var feedViewModel = ViewModel()
    @StateObject var discoverViewModel = DiscoverViewModel()

    @State private var feedType: FeedType = .following
    @State private var showFindFriendsSheet = false
    @State private var showEnableLocationButton = false

    var onCreatePostTap: () -> Void

    private let columns: [GridItem] = [
        GridItem(.fixed(UIScreen.main.bounds.width), spacing: 0)
    ]

    private func loadMore() {
        if feedViewModel.loadingMorePosts {
            return
        }
        feedViewModel.loadMorePosts(appState: appState, globalViewState: viewState)
    }

    var body: some View {
        Group {
            if !feedViewModel.initialized {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        feedViewModel.refreshFeed(appState: appState, globalViewState: viewState)
                        discoverViewModel.loadDiscoverPage(appState: appState)
                    }
            } else if feedViewModel.feed.isEmpty {
                Button(action: {
                    onCreatePostTap()
                }) {
                    HStack {
                        Image("postIcon")
                            .font(.system(size: 15))
                        Text("Create a post to get started")
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            } else {
                VStack {
                    HStack {
                        Picker("Feed Type", selection: $feedType) {
                            Label("Following", systemImage: "person.3.fill").tag(FeedType.following)
                            Label("For You", systemImage: "wand.and.stars").tag(FeedType.forYou)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, 10)
                    TabView(selection: $feedType) {
                        initializedFeed.tag(FeedType.following)
                        forYouFeed.tag(FeedType.forYou)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onAppear {
                        Analytics.currentScreen = feedType == .following ? .feedTab : .forYouFeed
                    }
                    .onChange(of: feedType) { feedType in
                        Analytics.currentScreen = feedType == .following ? .feedTab : .forYouFeed
                    }
                    .animation(.linear, value: feedType)
                }
            }
        }
        .background(Color("background"))
        .fullScreenCover(isPresented: $showFindFriendsSheet) {
            SearchUsers()
                .environmentObject(appState)
                .environmentObject(viewState)
        }
        .onAppear {
            showEnableLocationButton = PermissionManager.shared.getLocation() == nil
        }
        .onChange(of: scenePhase) { _ in
            showEnableLocationButton = PermissionManager.shared.getLocation() == nil
        }
    }

    var initializedFeed: some View {
        RefreshableScrollView {
            FindFriendsButton(showFindFriendsSheet: $showFindFriendsSheet)
                .padding(.bottom, 10)

            ForEach(feedViewModel.feed) { post in
                FeedItem(post: post)
            }
        } onRefresh: { onFinish in
            feedViewModel.refreshFeed(appState: appState, globalViewState: viewState, onFinish: onFinish)
        } onLoadMore: {
            feedViewModel.loadMorePosts(appState: appState, globalViewState: viewState)
        }
    }

    var forYouFeed: some View {
        RefreshableScrollView {
            if showEnableLocationButton {
                EnableLocationButton()
                    .padding(.bottom, 10)
            }

            ForEach(discoverViewModel.posts) { post in
                FeedItem(post: post)
            }
        } onRefresh: { onFinish in
            discoverViewModel.loadDiscoverPage(appState: appState, onFinish: onFinish)
        }
    }
}

extension Feed {
    class ViewModel: ObservableObject {
        let nc = NotificationCenter.default

        @Published var feed: [Post] = []
        @Published var initialized = false
        @Published var loadingMorePosts = false

        var cursor: String?

        var refreshFeedCancellable: AnyCancellable?
        var listenToFeedCancellable: AnyCancellable?

        init() {
            nc.addObserver(self, selector: #selector(postCreated), name: PostPublisher.postCreated, object: nil)
            nc.addObserver(self, selector: #selector(postUpdated), name: PostPublisher.postUpdated, object: nil)
            nc.addObserver(self, selector: #selector(postLiked), name: PostPublisher.postLiked, object: nil)
            nc.addObserver(self, selector: #selector(postSaved), name: PostPublisher.postSaved, object: nil)
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

        @objc private func postSaved(notification: Notification) {
            let save = notification.object as! PostSavePayload
            let postIndex = feed.indices.first(where: { feed[$0].postId == save.postId })
            if let i = postIndex {
                feed[i].saved = save.saved
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

}

private struct FindFriendsButton: View {
    @Binding var showFindFriendsSheet: Bool

    var body: some View {
        Button(action: {
            Analytics.track(.feedFindFriendsTapped)
            showFindFriendsSheet = true
        }) {
            Text("Find more people to follow")
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

private struct EnableLocationButton: View {
    var body: some View {
        Button(action: {
            PermissionManager.shared.requestLocation()
        }) {
            Text("Enable your location for better recs")
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
