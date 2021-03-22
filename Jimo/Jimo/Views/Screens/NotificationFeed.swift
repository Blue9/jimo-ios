//
//  NotificationFeed.swift
//  Jimo
//
//  Created by Jeff Rohlman on 3/2/21.
//

import SwiftUI
import Combine

class NotificationFeedVM: ObservableObject {
    private var appState: AppState?
    private var initialized = false
    
    @Published var feedItems: [NotificationItem] = []
    @Published var loadingMoreNotifications = false

    private var cancellable: Cancellable? = nil
    private var token: PaginationToken = PaginationToken()

    func initialize(appState: AppState) {
        if initialized {
            return
        }
        initialized = true
        self.appState = appState
        refreshFeed()
    }
    
    func refreshFeed() {
        guard let appState = appState else {
            return
        }
        self.token = PaginationToken()
        cancellable = appState.getNotificationsFeed(token: token)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Error while load notification feed.", error)
                }
                self?.scrollViewRefresh = false
            }, receiveValue: { [weak self] response in
                self?.feedItems = response.notifications
                self?.token = response.token
            })
    }
    
    func loadMoreNotifications() {
        guard let appState = appState else {
            return
        }
        if feedItems.count < 50 {
            // This prevents from spamming the API when there is less than a full page of results
            return
        }
        loadingMoreNotifications = true
        print("Loading more notifications")
        cancellable = appState.getNotificationsFeed(token: token)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Error while load more notifications.", error)
                }
                self?.loadingMoreNotifications = false
            }, receiveValue: { [weak self] response in
                self?.feedItems.append(contentsOf: response.notifications)
                self?.token = response.token
            })
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
                return AnyView(ViewPost(postId: post.id))
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
                    } else if item.type == ItemType.like {
                        Text(item.user.username + " has liked your post!")
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
                    Spacer()
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
        RefreshableScrollView(refreshing: $notificationFeedVM.scrollViewRefresh) {
            Divider()
                .padding(.bottom, 5)
                .hidden()
            ForEach(notificationFeedVM.feedItems, id: \.self) { item in
                NotificationFeedItem(item: item)
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
                    .environment(\.backgroundColor, backgroundColor)
                    .padding(.horizontal, 10)
                Divider()
                    .padding(.horizontal, 10)
                    .hidden()
            }
            .listStyle(PlainListStyle())
            
            LazyVStack {
                Divider()
                    .onAppear {
                        notificationFeedVM.loadMoreNotifications()
                    }
                ProgressView()
                    .opacity(notificationFeedVM.loadingMoreNotifications ? 1 : 0)
                Text("You've reached the end!")
                    .font(Font.custom(Poppins.medium, size: 15))
            }
        }
        .onAppear(perform: { notificationFeedVM.initialize(appState: appState) })
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(backgroundColor))
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                NavTitle("Notifications")
            }
        })
    }
}
