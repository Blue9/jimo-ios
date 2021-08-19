//
//  Feed.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI
import Combine
import ASCollectionView

class FeedViewModel: ObservableObject {
    let nc = NotificationCenter.default
    
    @Published var feed: [Post] = []
    @Published var initialized = false
    @Published var loadingMorePosts = false
    
    var cursor: String?
    
    var refreshFeedCancellable: AnyCancellable?
    var listenToFeedCancellable: AnyCancellable?
    
    init() {
        nc.addObserver(self, selector: #selector(postCreated), name: PostPublisher.postCreated, object: nil)
        nc.addObserver(self, selector: #selector(postLiked), name: PostPublisher.postLiked, object: nil)
        nc.addObserver(self, selector: #selector(postDeleted), name: PostPublisher.postDeleted, object: nil)
    }
    
    @objc private func postCreated(notification: Notification) {
        let post = notification.object as! Post
        feed.insert(post, at: 0)
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
    @Environment(\.backgroundColor) var backgroundColor
    @StateObject var feedViewModel = FeedViewModel()
    
    private func loadMore() {
        if feedViewModel.loadingMorePosts {
            return
        }
        feedViewModel.loadMorePosts(appState: appState, globalViewState: viewState)
    }
    
    var collectionView: ASCollectionView<Int> {
        ASCollectionView {
            ASCollectionViewSection(id: 0, data: feedViewModel.feed) { post, _ in
                FeedItem(post: post)
            }
            .cacheCells()
            
            ASCollectionViewSection(id: 1) {
                VStack {
                    Divider()
                    
                    ProgressView()
                        .opacity(feedViewModel.loadingMorePosts ? 1 : 0)
                    Text("You've reached the end!")
                        .font(Font.custom(Poppins.medium, size: 15))
                        .padding()
                }
            }
        }
    }
    
    var initializedFeed: some View {
        collectionView
            .shouldScrollToAvoidKeyboard(false)
            .layout {
                .list(itemSize: .estimated(200))
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
            .ignoresSafeArea(.keyboard, edges: .all)
            .edgesIgnoringSafeArea(.all)
    }
    
    var body: some View {
        Group {
            if !feedViewModel.initialized {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        feedViewModel.refreshFeed(appState: appState, globalViewState: viewState)
                    }
            } else {
                initializedFeed
            }
        }
        .background(backgroundColor)
    }
}

struct Feed: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    
    @State private var showFeedback = false
    @State private var showInvite = false
    @State private var showNotifications = false
    
    @StateObject private var notificationFeedVM = NotificationFeedVM()

    var body: some View {
        NavigationView {
            FeedBody()
                .background(
                    NavigationLink(destination: NotificationFeed()
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState)
                                    .environment(\.backgroundColor, backgroundColor), isActive: $showNotifications) {}
                )
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarColor(UIColor(backgroundColor))
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showInvite.toggle() }) {
                            Image(systemName: "person.crop.circle.badge.plus")
                        }
                        .sheet(isPresented: $showInvite) {
                            NavigationView {
                                InviteContactsView()
                            }
                            .environmentObject(appState)
                            .environment(\.backgroundColor, backgroundColor)
                            .preferredColorScheme(.light)
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        NavTitle("Feed")
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { self.showNotifications.toggle() }) {
                            Image(systemName: "bell")
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showFeedback.toggle() }) {
                            Image(systemName: "exclamationmark.bubble")
                        }
                        .sheet(isPresented: $showFeedback) {
                            Feedback(presented: $showFeedback)
                                .environmentObject(appState)
                                .environment(\.backgroundColor, backgroundColor)
                                .preferredColorScheme(.light)
                        }
                    }
                })
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct Feed_Previews: PreviewProvider {
    static let api = APIClient()
    static var previews: some View {
        Feed()
            .environmentObject(AppState(apiClient: api))
            .environmentObject(GlobalViewState())
    }
}
