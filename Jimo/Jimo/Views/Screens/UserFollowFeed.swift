//
//  UserFollowFeed.swift
//  Jimo
//
//  Created by Jeff Rohlman on 5/10/21.
//

import SwiftUI
import Combine
import ASCollectionView

enum FollowType {
    case followers
    case following
}

class FollowFeedVM: ObservableObject {
    let nc = NotificationCenter.default
    
    @Published var feedItems: [FollowFeedItem] = []
    @Published var loadingMoreFollows = false

    private var cancellable: Cancellable?
    private var cursor: String?
    
    init() {
        nc.addObserver(self, selector: #selector(userRelationChanged), name: UserPublisher.userRelationChanged, object: nil)
    }
    
    @objc private func userRelationChanged(notification: Notification) {
        let payload = notification.object as! UserRelationPayload
        let feedIndex = feedItems.indices.first(where: { feedItems[$0].user.username == payload.username })
        if let i = feedIndex {
            feedItems[i].relation = payload.relation
        }
    }
    
    func refreshFollows(
        type: FollowType,
        for username: String,
        appState: AppState,
        viewState: GlobalViewState,
        onFinish: OnFinish? = nil
    ) {
        self.cursor = nil
        cancellable = callApi(appState: appState, type: type, username: username, cursor: nil)
            .sink(receiveCompletion: { completion in
                onFinish?()
                if case let .failure(error) = completion {
                    print("Error while load follows feed.", error)
                    viewState.setError("Failed to load.")
                }
            }, receiveValue: { [weak self] response in
                self?.feedItems = response.users
                self?.cursor = response.cursor
            })
    }
    
    func loadMoreFollows(type: FollowType, for username: String, appState: AppState, viewState: GlobalViewState) {
        guard cursor != nil else {
            return
        }
        loadingMoreFollows = true
        print("Loading more follows")
        cancellable = callApi(appState: appState, type: type, username: username, cursor: cursor)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Error while load more follows.", error)
                    viewState.setError("Failed to load.")
                }
                self?.loadingMoreFollows = false
            }, receiveValue: { [weak self] response in
                self?.feedItems.append(contentsOf: response.users)
                self?.cursor = response.cursor
            })
    }
    
    func callApi(
        appState: AppState,
        type: FollowType,
        username: String,
        cursor: String?
    ) -> AnyPublisher<FollowFeedResponse, APIError> {
        if type == FollowType.followers {
            return appState.getFollowers(username: username, cursor: cursor)
        } else {
            return appState.getFollowing(username: username, cursor: cursor)
        }
    }
}

class FollowFeedItemVM: ObservableObject {
    private var relationCancellable: AnyCancellable?
    
    func followUser(appState: AppState, viewState: GlobalViewState, item: FollowFeedItem) {
        relationCancellable = appState.followUser(username: item.user.username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when following", error)
                    viewState.setError("Failed to follow user.")
                }
            }, receiveValue: { _ in })
    }

    func unfollowUser(appState: AppState, viewState: GlobalViewState, item: FollowFeedItem) {
        relationCancellable = appState.unfollowUser(username: item.user.username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when unfollowing", error)
                    viewState.setError("Failed to unfollow user.")
                }
            }, receiveValue: { _ in })
    }
    
    func unblockUser(appState: AppState, viewState: GlobalViewState, item: FollowFeedItem) {
        relationCancellable = appState.unblockUser(username: item.user.username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when unblocking", error)
                    viewState.setError("Failed to unblock user.")
                }
            }, receiveValue: { _ in })
    }
}

struct FollowFeedItemButton: View {
    @Environment(\.colorScheme) var colorScheme
    let action: () -> ()
    let text: String
    let background: Color
    let foreground: Color
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            Text(text)
                .padding(5)
                .font(.system(size: 14))
                .background(background)
                .cornerRadius(2)
                .foregroundColor(foreground)
                .overlay(
                    colorScheme == .light ? RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.gray, lineWidth: 1) : nil
                )
        }.frame(height: 30)
    }
}

struct FollowFeedItemView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @StateObject var followFeedItemVM = FollowFeedItemVM()
    
    let item: FollowFeedItem
    let defaultProfileImage = Image(systemName: "person.crop.circle")
    
    var isCurrentUser: Bool {
        guard case let .user(currentUser) = appState.currentUser else {
            return false
        }
        return item.user.username == currentUser.username
    }
    
    func profilePicture(user: User) -> some View {
        URLImage(url: user.profilePictureUrl, loading: defaultProfileImage)
            .frame(width: 40, height: 40, alignment: .center)
            .font(Font.title.weight(.ultraLight))
            .foregroundColor(.gray)
            .background(Color.white)
            .cornerRadius(50)
    }
    
    @ViewBuilder var destinationView: some View {
        ProfileScreen(initialUser: item.user)
    }
    
    @ViewBuilder var followItemButton: some View {
        if item.relation == .following {
            FollowFeedItemButton(
                action: { followFeedItemVM.unfollowUser(appState: appState, viewState: globalViewState, item: item) },
                text: "Following",
                background: .white,
                foreground: .gray
            )
        } else if item.relation == .blocked {
            FollowFeedItemButton(
                action: { followFeedItemVM.unblockUser(appState: appState, viewState: globalViewState, item: item) },
                text: "Unblock",
                background: .red,
                foreground: .white
            )
        } else {
            FollowFeedItemButton(
                action: { followFeedItemVM.followUser(appState: appState, viewState: globalViewState, item: item) },
                text: "Follow",
                background: .blue,
                foreground: .white
            )
        }
    }

    var body: some View {
        NavigationLink(destination: destinationView) {
            HStack {
                profilePicture(user: item.user)
                
                VStack(alignment: .leading) {
                    Text("@" + item.user.username)
                        .font(.system(size: 14))
                    Text(item.user.firstName + " " + item.user.lastName)
                        .lineLimit(1)
                        .font(.system(size: 12))
                }
                
                Spacer()
                
                if (!isCurrentUser) {
                    followItemButton
                }
            }
        }
        .buttonStyle(NoButtonStyle())
    }
}


struct FollowFeed: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @StateObject var followFeedVM = FollowFeedVM()
    @State private var initialized = false
    
    let navTitle: String
    let type: FollowType
    let username: String
    
    var body: some View {
        ASCollectionView {
            ASCollectionViewSection(id: 1, data: followFeedVM.feedItems) { item, _ in
                FollowFeedItemView(item: item)
                    .environmentObject(appState)
                    .environmentObject(globalViewState)
                    .padding(.horizontal, 10)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .sectionFooter {
                VStack {
                    Divider()
                    
                    ProgressView()
                        .opacity(followFeedVM.loadingMoreFollows ? 1 : 0)
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
            followFeedVM.refreshFollows(
                type: type,
                for: username,
                appState: appState,
                viewState: globalViewState,
                onFinish: onFinish
            )
        }
        .onReachedBoundary { boundary in
            if boundary == .bottom {
                followFeedVM.loadMoreFollows(
                    type: type,
                    for: username,
                    appState: appState,
                    viewState: globalViewState
                )
            }
        }
        .ignoresSafeArea(.keyboard, edges: .all)
        .onAppear {
            if !initialized {
                followFeedVM.refreshFollows(type: type, for: username, appState: appState, viewState: globalViewState)
                initialized = true
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                NavTitle(self.navTitle)
            }
        })
    }
}
