//
//  Feed.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI
import Combine
import ASCollectionView

class FeedViewState: ObservableObject {
    let appState: AppState
    let globalViewState: GlobalViewState
    
    var refreshFeedCancellable: AnyCancellable?
    var listenToFeedCancellable: AnyCancellable?
    
    @Published var initialized = false
    @Published var loadingMorePosts = false
    @Published var feed: [PostId] = []
    
    init(appState: AppState, globalViewState: GlobalViewState) {
        self.appState = appState
        self.globalViewState = globalViewState
    }
    
    func refreshFeed(onFinish: OnFinish? = nil) {
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
                    self.globalViewState.setError("Could not refresh feed")
                }
            }, receiveValue: { [weak self] feed in
                withAnimation {
                    self?.feed = feed
                    self?.initialized = true
                }
            })
    }
    
    func listenToFeedChanges() {
        listenToFeedCancellable = appState.feedModel.$currentFeed
            .sink { [weak self] feed in
                withAnimation {
                    self?.feed = feed
                }
            }
    }
    
    func stopListeningToFeedChanges() {
        listenToFeedCancellable?.cancel()
    }
    
    func loadMorePosts() {
        if loadingMorePosts {
            return
        }
        loadingMorePosts = true
        print("Loading more posts")
        refreshFeedCancellable = appState.loadMoreFeedItems()
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else {
                    return
                }
                self.loadingMorePosts = false
                if case let .failure(error) = completion {
                    print("Error when loading more posts", error)
                    self.globalViewState.setError("Could not load more posts")
                }
            }, receiveValue: {})
    }
}

struct FeedBody: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    @StateObject var feedState: FeedViewState
    
    private func loadMore() {
        if feedState.feed.count < 50 {
            return
        }
        if feedState.loadingMorePosts {
            return
        }
        feedState.loadMorePosts()
    }
    
    var body: some View {
        Group {
            if !feedState.initialized {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        feedState.refreshFeed()
                    }
            } else {
                ASCollectionView {
                    ASCollectionViewSection(id: 1, data: feedState.feed, dataID: \.self) { postId, _ in
                        if postId == "" {
                            /// This is explained below
                            EmptyView()
                                .frame(width: 0, height: 0)
                                .hidden()
                        } else {
                            FeedItem(feedItemVM: FeedItemVM(appState: appState, viewState: viewState, postId: postId))
                                .frame(width: UIScreen.main.bounds.width)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    ASCollectionViewSection(id: 2) {
                        VStack {
                            Divider()
                            
                            ProgressView()
                                .opacity(feedState.loadingMorePosts ? 1 : 0)
                            Text("You've reached the end!")
                                .font(Font.custom(Poppins.medium, size: 15))
                                .padding()
                        }
                    }
                }
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
                    feedState.refreshFeed(onFinish: onFinish)
                }
                .appear {
                    feedState.listenToFeedChanges()
                    /// This is a hack that forces the collection view to refresh. Without this, if a feed item resizes
                    /// itself (e.g. when editing), its bounding box won't refresh, so the feed item's layout will get messed up.
                    /// There is also `.shouldRecreateLayoutOnStateChange()` which works but is noticeably slower and doesn't look as nice
                    feedState.feed.append("")
                }
                .disappear {
                    feedState.stopListeningToFeedChanges()
                }
                .ignoresSafeArea(.keyboard, edges: .all)
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
            FeedBody(feedState: FeedViewState(appState: appState, globalViewState: globalViewState))
                .background(
                    NavigationLink(destination: NotificationFeed(notificationFeedVM: notificationFeedVM)
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
