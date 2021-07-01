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
    private var appState: AppState?
    private var initialized = false
    
    @Published var user: User
    @Published var type: FollowType
    @Published var feedItems: [FollowFeedItem] = []
    @Published var loadingMoreFollows = false

    private var cancellable: Cancellable? = nil
    private var cursor: String?
    
    init(user: User, type: FollowType) {
        self.user = user
        self.type = type
    }
    
    func initialize(appState: AppState) {
        if initialized {
            return
        }
        initialized = true
        self.appState = appState
        refreshFeed()
    }
    
    func refreshFeed(onFinish: OnFinish? = nil) {
        guard appState != nil else {
            onFinish?()
            return
        }
        self.cursor = nil
        cancellable = callApi(cursor: nil)
            .sink(receiveCompletion: { completion in
                onFinish?()
                if case let .failure(error) = completion {
                    print("Error while load follows feed.", error)
                }
            }, receiveValue: { [weak self] response in
                self?.feedItems = response.users.filter { $0.relation != UserRelation.blocked }
                self?.cursor = response.cursor
            })
    }
    
    func loadMoreFollows() {
        guard appState != nil, cursor != nil else {
            return
        }
        loadingMoreFollows = true
        print("Loading more follows")
        cancellable = callApi(cursor: cursor)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Error while load more follows.", error)
                }
                self?.loadingMoreFollows = false
            }, receiveValue: { [weak self] response in
                self?.feedItems.append(contentsOf: response.users.filter { $0.relation != UserRelation.blocked })
                self?.cursor = response.cursor
            })
    }
    
    func callApi(cursor: String?) -> AnyPublisher<FollowFeedResponse, APIError> {
        if type == FollowType.followers {
            return appState!.getFollowers(username: user.username, cursor: cursor)
        } else {
            return appState!.getFollowing(username: user.username, cursor: cursor)
        }
    }
}

class FollowFeedItemVM: ObservableObject {
    var appState: AppState
    @Published var relation: UserRelation?
    private var relationCancellable: AnyCancellable? = nil
    
    
    init(appState: AppState, relation: UserRelation?) {
        self.relation = relation
        self.appState = appState
    }
    
    func followUser(item: FollowFeedItem){
        relationCancellable = appState.followUser(username: item.user.username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when following", error)
                }
            }, receiveValue: { [self] _ in
                self.relation = UserRelation.following
            })
    }

    func unfollowUser(item: FollowFeedItem) {
        relationCancellable = appState.unfollowUser(username: item.user.username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when unfollowing", error)
                }
            }, receiveValue: { [self] _ in
                self.relation = nil
            })
    }
}

struct FollowFeedItemView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @ObservedObject var followFeedItemVM: FollowFeedItemVM
    @Environment(\.backgroundColor) var backgroundColor
    
    var item: FollowFeedItem
    
    let defaultProfileImage: Image = Image(systemName: "person.crop.circle")
    
    func profilePicture(user: User) -> some View {
        URLImage(url: user.profilePictureUrl, loading: defaultProfileImage, failure: defaultProfileImage)
            .frame(width: 40, height: 40, alignment: .center)
            .font(Font.title.weight(.ultraLight))
            .foregroundColor(.gray)
            .background(Color.white)
            .cornerRadius(50)
            .padding(.trailing)
    }
    
    var destinationView: some View {
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
    
    var isCurrentUser: Bool {
        guard case let .user(currentUser) = appState.currentUser else {
            return false
        }
        return item.user.username == currentUser.username
    }

    var body: some View {
        NavigationLink(destination: destinationView) {
            HStack {
                profilePicture(user: item.user)
                
                VStack(alignment: .leading) {
                    Text("@" + item.user.username)
                    Text(item.user.firstName + " " + item.user.lastName)
                        .lineLimit(1)
                }
                Spacer()
                if (!isCurrentUser) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        followFeedItemVM.relation != nil ?
                            followFeedItemVM.unfollowUser(item: item)
                            : followFeedItemVM.followUser(item: item)
                    }) {
                        Text(followFeedItemVM.relation != nil ? "Following" : "Follow")
                            .padding(5)
                            .font(Font.custom(Poppins.regular, size: 14))
                            .background(followFeedItemVM.relation != nil ? Color.white : Color.blue)
                            .cornerRadius(10)
                            .foregroundColor(followFeedItemVM.relation != nil ? .gray : .white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }.frame(height: 30)
                }
            }
        }
        .buttonStyle(NoButtonStyle())
    }
}


struct FollowFeed: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @ObservedObject var followFeedVM: FollowFeedVM
    @Environment(\.backgroundColor) var backgroundColor
    
    var navTitle: String
    
    var body: some View {
        ASCollectionView {
            ASCollectionViewSection(id: 1, data: followFeedVM.feedItems, dataID: \.self) { item, _ in
                FollowFeedItemView(followFeedItemVM: FollowFeedItemVM(appState: appState, relation: item.relation), item: item)
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
                        .opacity(followFeedVM.loadingMoreFollows ? 1 : 0)
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
            followFeedVM.refreshFeed(onFinish: onFinish)
        }
        .onReachedBoundary { boundary in
            if boundary == .bottom {
                followFeedVM.loadMoreFollows()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .all)
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .onAppear(perform: { followFeedVM.initialize(appState: appState) })
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(backgroundColor))
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                NavTitle(self.navTitle)
            }
        })
    }
}
