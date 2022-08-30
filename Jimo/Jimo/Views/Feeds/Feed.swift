//
//  Feed.swift
//  Jimo
//
//  Created by Gautam Mekkat on 7/26/22.
//

import SwiftUI
import Combine
import ASCollectionView

struct Feed: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @StateObject var feedViewModel = ViewModel()
    
    @State private var showFullPost: PostId?
    
    var onCreatePostTap: () -> ()
    
    private let columns: [GridItem] = [
        GridItem(.fixed(UIScreen.main.bounds.width), spacing: 0)
    ]
    
    private func loadMore() {
        if feedViewModel.loadingMorePosts {
            return
        }
        feedViewModel.loadMorePosts(appState: appState, globalViewState: viewState)
    }
    
    @ViewBuilder
    private func postView(for postId: PostId?) -> some View {
        if let post = feedViewModel.feed.first(where: { $0.id == postId }) {
            ViewPost(initialPost: post)
        } else {
            EmptyView().onAppear { showFullPost = nil }
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
                        Text("Create a post to get started")
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
    
    var initializedFeed: some View {
        ASCollectionView(data: feedViewModel.feed, dataID: \.self) { post, _ in
            FeedItem(post: post, showFullPost: $showFullPost)
                .frame(width: UIScreen.main.bounds.width)
                .fixedSize()
        }
        .shouldScrollToAvoidKeyboard(false)
        .layout {
            .list(itemSize: .estimated(200), spacing: 20)
        }
        .alwaysBounceVertical()
        .onReachedBoundary { boundary in
            if boundary == .bottom {
                loadMore()
            }
        }
        .scrollIndicatorsEnabled(horizontal: false, vertical: false)
        .onPullToRefresh { onFinish in
            feedViewModel.refreshFeed(appState: appState, globalViewState: viewState, onFinish: onFinish)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigation(item: $showFullPost, destination: postView)
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