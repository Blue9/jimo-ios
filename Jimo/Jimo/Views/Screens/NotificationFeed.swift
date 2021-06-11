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
    private var appState: AppState?
    private var initialized = false
    
    @Published var feedItems: [NotificationItem] = []
    @Published var loadingMoreNotifications = false

    private var cancellable: Cancellable? = nil
    private var cursor: String?
    
    func initialize(appState: AppState) {
        if initialized {
            return
        }
        initialized = true
        self.appState = appState
        refreshFeed()
    }
    
    func refreshFeed(onFinish: OnFinish? = nil) {
        guard let appState = appState else {
            onFinish?()
            return
        }
        self.cursor = nil
        cancellable = appState.getNotificationsFeed(token: nil)
            .sink(receiveCompletion: { completion in
                onFinish?()
                if case let .failure(error) = completion {
                    print("Error while load notification feed.", error)
                }
            }, receiveValue: { [weak self] response in
                self?.feedItems = response.notifications.filter{ item in item.type != .unknown }
                self?.cursor = response.cursor
            })
    }
    
    func loadMoreNotifications() {
        guard let appState = appState, cursor != nil else {
            return
        }
        loadingMoreNotifications = true
        print("Loading more notifications")
        cancellable = appState.getNotificationsFeed(token: cursor)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Error while load more notifications.", error)
                }
                self?.loadingMoreNotifications = false
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
    let item: NotificationItem
    
    @State private var relativeTime: String = ""
    let formatter = RelativeDateTimeFormatter()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    let defaultProfileImage: Image = Image(systemName: "person.crop.circle")
    let defaultPostImage: Image = Image(systemName: "square")
    
    func getRelativeTime() -> String {
        if Date().timeIntervalSince(item.createdAt) < 1 {
            return "just now"
        }
        return formatter.localizedString(for: item.createdAt, relativeTo: Date())
    }
    
    func profilePicture(user: User) -> some View {
        URLImage(url: user.profilePictureUrl, loading: defaultProfileImage, failure: defaultProfileImage)
            .frame(width: 40, height: 40, alignment: .center)
            .font(Font.title.weight(.ultraLight))
            .foregroundColor(.gray)
            .background(Color.white)
            .cornerRadius(50)
            .padding(.trailing)
    }
    
    func postPreview(post: Post) -> some View {
        URLImage(url: post.imageUrl, loading: defaultPostImage, failure: defaultPostImage)
            .scaledToFill()
            .frame(width: 50, height: 50, alignment: .center)
            .clipped()
            .border(Color(post.category), width: 2)
            .padding(.trailing)
    }
    
    var destinationView: some View {
        if item.type == ItemType.like {
            if let post = item.post {
                return AnyView(ViewPost(postId: post.postId))
            }
        }
        return AnyView(
            Profile(profileVM: ProfileVM(appState: appState, globalViewState: globalViewState, user: item.user))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor(UIColor(backgroundColor))
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    NavTitle("Profile")
                }
            })
        )
    }

    var body: some View {
        NavigationLink(destination: destinationView) {
            HStack {
                profilePicture(user: item.user)
                
                VStack(alignment: .leading) {
                    if item.type == ItemType.follow {
                        Text(item.user.username + " has followed you!")
                            .lineLimit(1)
                    } else if item.type == ItemType.like {
                        Text(item.user.username + " has liked your post!")
                            .lineLimit(1)
                    }
                    Text(relativeTime)
                        .font(Font.custom(Poppins.regular, size: 13))
                        .foregroundColor(.gray)
                        .onReceive(timer, perform: { _ in
                            relativeTime = getRelativeTime()
                        })
                        .onAppear(perform: {
                            relativeTime = getRelativeTime()
                        })
                }
                
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
    @ObservedObject var notificationFeedVM: NotificationFeedVM
    @Environment(\.backgroundColor) var backgroundColor
    
    var body: some View {
        ASCollectionView {
            ASCollectionViewSection(id: 1, data: notificationFeedVM.feedItems, dataID: \.self) { item, _ in
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
            .sectionHeader {
                Divider()
                    .padding(.bottom, 5)
                    .hidden()
            }
            .sectionFooter {
                VStack {
                    Divider()
                    
                    ProgressView()
                        .opacity(notificationFeedVM.loadingMoreNotifications ? 1 : 0)
                    Text("You've reached the end!")
                        .font(Font.custom(Poppins.medium, size: 15))
                }
            }
        }
        .alwaysBounceVertical()
        .shouldScrollToAvoidKeyboard(false)
        .layout {
            .list(itemSize: .absolute(50))
        }
        .onPullToRefresh { onFinish in
            notificationFeedVM.refreshFeed(onFinish: onFinish)
        }
        .onReachedBoundary { boundary in
            if boundary == .bottom {
                notificationFeedVM.loadMoreNotifications()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .all)
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .onAppear(perform: { notificationFeedVM.initialize(appState: appState) })
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(backgroundColor))
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                NavTitle("Notifications")
            }
        })
    }
}
