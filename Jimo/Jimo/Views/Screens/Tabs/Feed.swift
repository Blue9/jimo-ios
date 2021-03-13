//
//  Feed.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI
import Combine


class FeedViewState: ObservableObject {
    let appState: AppState
    let globalViewState: GlobalViewState
    
    var cancellable: Cancellable? = nil
    @Published var initialized = false
    @Published var loadingMorePosts = false
    
    init(appState: AppState, globalViewState: GlobalViewState) {
        self.appState = appState
        self.globalViewState = globalViewState
    }
    
    func refreshFeed() {
        cancellable = appState.refreshFeed()
            .sink(receiveCompletion: { [weak self] completion in
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
                self.scrollViewRefresh = false
            }, receiveValue: {})
    }
    
    func loadMorePosts() {
        loadingMorePosts = true
        print("Loading more posts")
        cancellable = appState.loadMoreFeedItems()
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
    
    @Published var scrollViewRefresh = false {
        didSet {
            if oldValue == false && scrollViewRefresh == true {
                print("Refreshing")
                refreshFeed()
            }
        }
    }
}

struct FeedBody: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    @ObservedObject var feedModel: FeedModel
    @StateObject var feedState: FeedViewState
    
    var body: some View {
        Group {
            if !feedState.initialized {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear {
                        feedState.refreshFeed()
                    }
            } else {
                RefreshableScrollView(refreshing: $feedState.scrollViewRefresh) {
                    ForEach(feedModel.currentFeed, id: \.self) { postId in
                        FeedItem(feedItemVM: FeedItemVM(appState: appState, viewState: viewState, postId: postId))
                    }
                    LazyVStack {
                        // LazyVStack makes sure onAppear only gets called when the view is actually on the screen
                        Divider()
                            .onAppear {
                                feedState.loadMorePosts()
                            }
                        ProgressView()
                            .opacity(feedState.loadingMorePosts ? 1 : 0)
                        Text("You've reached the end!")
                            .font(Font.custom(Poppins.medium, size: 15))
                            .padding()
                    }
                }
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
    
    @StateObject private var notificationFeedVm = NotificationFeedVM()

    var body: some View {
        NavigationView {
            FeedBody(feedModel: appState.feedModel, feedState: FeedViewState(appState: appState, globalViewState: globalViewState))
                .background(
                    NavigationLink(destination: NotificationFeed(notificationFeedVM: notificationFeedVm)
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
