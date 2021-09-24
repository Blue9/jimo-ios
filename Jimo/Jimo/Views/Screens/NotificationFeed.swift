//
//  NotificationFeed.swift
//  Jimo
//
//  Created by Jeff Rohlman on 3/2/21.
//

import SwiftUI
import Combine
import ASCollectionView

class NotificationFeedVM: ObservableObject {
    @Published var feedItems: [NotificationItem] = []
    @Published var loading = false

    private var cancellable: Cancellable?
    private var cursor: String?
    
    func refreshFeed(appState: AppState, viewState: GlobalViewState, onFinish: OnFinish? = nil) {
        cursor = nil
        loading = true
        cancellable = appState.getNotificationsFeed(token: nil)
            .sink(receiveCompletion: { [weak self] completion in
                self?.loading = false
                onFinish?()
                if case let .failure(error) = completion {
                    print("Error while load notification feed.", error)
                    viewState.setError("Could not load activity feed.")
                }
            }, receiveValue: { [weak self] response in
                self?.feedItems = response.notifications.filter{ item in item.type != .unknown }
                self?.cursor = response.cursor
            })
    }
    
    func loadMoreNotifications(appState: AppState, viewState: GlobalViewState) {
        guard cursor != nil else {
            return
        }
        loading = true
        print("Loading more notifications")
        cancellable = appState.getNotificationsFeed(token: cursor)
            .sink(receiveCompletion: { [weak self] completion in
                self?.loading = false
                if case let .failure(error) = completion {
                    print("Error while load more notifications.", error)
                    viewState.setError("Could not load more items.")
                }
            }, receiveValue: { [weak self] response in
                self?.feedItems.append(contentsOf: response.notifications.filter{ item in item.type != .unknown })
                self?.cursor = response.cursor
            })
    }
}

struct NotificationFeedItem: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    
    @State private var relativeTime: String = ""
    
    let item: NotificationItem
    let defaultProfileImage: Image = Image(systemName: "person.crop.circle")
    let defaultPostImage: Image = Image(systemName: "square")
    
    func getRelativeTime() -> String {
        if Date().timeIntervalSince(item.createdAt) < 1 {
            return "just now"
        }
        return appState.dateTimeFormatter.localizedString(for: item.createdAt, relativeTo: Date())
    }
    
    func profilePicture(user: User) -> some View {
        URLImage(url: user.profilePictureUrl, loading: defaultProfileImage, failure: defaultProfileImage)
            .frame(width: 40, height: 40, alignment: .center)
            .font(Font.title.weight(.ultraLight))
            .foregroundColor(.gray)
            .background(Color.white)
            .cornerRadius(50)
            .padding(.trailing, 5)
    }
    
    func postPreview(post: Post) -> some View {
        URLImage(url: post.imageUrl, loading: defaultPostImage, failure: defaultPostImage)
            .scaledToFill()
            .frame(width: 50, height: 50, alignment: .center)
            .clipped()
            .border(Color(post.category), width: 2)
            .padding(.trailing)
    }
    
    @ViewBuilder var destinationView: some View {
        if item.type == ItemType.like {
            if let post = item.post {
                ViewPost(post: post)
            }
        } else if item.type == ItemType.comment {
            if let post = item.post {
                ViewPost(post: post, highlightedComment: item.comment)
            }
        } else {
            ProfileScreen(initialUser: item.user)
        }
    }

    var body: some View {
        NavigationLink(destination: destinationView) {
            HStack {
                profilePicture(user: item.user)
                
                VStack(alignment: .leading) {
                    if item.type == ItemType.follow {
                        Text(item.user.username + " started following you.")
                            .lineLimit(1)
                    } else if item.type == ItemType.like {
                        Text(item.user.username + " liked your post.")
                            .lineLimit(1)
                    } else if item.type == ItemType.comment {
                        Text(item.user.username + " commented on your post.")
                            .lineLimit(1)
                    }
                    Text(relativeTime)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .onAppear {
                            if relativeTime == "" {
                                relativeTime = getRelativeTime()
                            }
                        }
                }
                .font(.system(size: 14))
                
                Spacer()
                
                if let post = item.post {
                    postPreview(post: post)
                }
            }
        }
        .buttonStyle(NoButtonStyle())
    }
}


struct NotificationFeed: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    
    @StateObject private var notificationFeedVM = NotificationFeedVM()
    
    @State private var initialized = false
    
    var body: some View {
        ASCollectionView {
            ASCollectionViewSection(id: 0, data: notificationFeedVM.feedItems) { item, _ in
                NotificationFeedItem(item: item)
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
                    .environment(\.backgroundColor, backgroundColor)
                    .padding(.horizontal, 10)
                    .fixedSize(horizontal: false, vertical: true)
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
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .onAppear {
            if !initialized {
                notificationFeedVM.refreshFeed(appState: appState, viewState: globalViewState)
                initialized = true
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(backgroundColor))
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                NavTitle("Notifications")
            }
        })
    }
}
