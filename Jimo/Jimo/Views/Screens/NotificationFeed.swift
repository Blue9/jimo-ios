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
    
    @Published var unreadNotifications: Int {
        didSet {
            UIApplication.shared.applicationIconBadgeNumber = unreadNotifications
        }
    }

    private var cancellable: Cancellable?
    private var cursor: String?
    
    init() {
        unreadNotifications = UIApplication.shared.applicationIconBadgeNumber
    }
    
    func readAllNotifications() {
        unreadNotifications = 0
    }
    
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
                NavigationLink(destination: ProfileScreen(initialUser: user)) {
                    profilePicture
                }
                
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
                                relativeTime = appState.relativeTime(for: item.createdAt)
                            }
                        }
                }
                .font(.system(size: 14))
                
                Spacer()
                
                postPreview
            }
        }
        .buttonStyle(NoButtonStyle())
    }
}


struct NotificationFeed: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @ObservedObject var notificationFeedVM: NotificationFeedVM
    
    @State private var initialized = false
    
    var body: some View {
        ASCollectionView {
            ASCollectionViewSection(id: 0, data: notificationFeedVM.feedItems) { item, _ in
                NotificationFeedItem(item: item)
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
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
                notificationFeedVM.readAllNotifications()
            }
        }
    }
}
