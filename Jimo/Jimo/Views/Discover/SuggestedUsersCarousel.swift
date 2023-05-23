//
//  SuggestedUsersCarousel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/11/22.
//

import SwiftUI
import Combine

private enum LoadStatus {
    case notInitialized, loaded, failed
}

private enum FollowButtonType: Equatable {
    case follow, unfollow

    var text: String {
        switch self {
        case .follow:
            return "Follow"
        case .unfollow:
            return "Unfollow"
        }
    }

    var backgroundColor: Color {
        switch self {
        case .follow:
            return .blue
        case .unfollow:
            return .white
        }
    }

    var hasBorder: Bool {
        self == .unfollow
    }

    var foregroundColor: Color {
        switch self {
        case .follow:
            return .white
        case .unfollow:
            return .gray
        }
    }
}

struct SuggestedUsersCarousel: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @ObservedObject var viewModel: SuggestedUserCarouselViewModel

    var navigate: (NavDestination) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(viewModel.users, id: \.self) { item in
                    SuggestedUserCard(
                        viewModel: viewModel,
                        navigate: navigate,
                        item: item
                    )
                }
            }.padding()
        }
    }
}

class SuggestedUserCarouselViewModel: ObservableObject {
    let nc = NotificationCenter.default

    @Published fileprivate var loadStatus: LoadStatus = .notInitialized
    @Published var users: [SuggestedUserItem] = []
    @Published var followedUsernames: Set<String> = []

    private var cancelBag: Set<AnyCancellable> = .init()
    private var initialized = false

    init() {
        nc.addObserver(self, selector: #selector(userRelationChanged), name: UserPublisher.userRelationChanged, object: nil)
    }

    @objc private func userRelationChanged(notification: Notification) {
        let payload = notification.object as! UserRelationPayload
        if users.contains(where: { $0.user.username == payload.username }) {
            switch payload.relation {
            case .blocked, .none:
                followedUsernames.remove(payload.username)
            case .following:
                followedUsernames.insert(payload.username)
            }
        }
    }

    func isFollowed(_ username: String) -> Bool {
        return followedUsernames.contains(username)
    }

    func shouldPresent() -> Bool {
        users.count > 0
    }

    func initialize(appState: AppState, viewState: GlobalViewState) {
        guard !initialized else {
            return
        }
        initialized = true
        appState.getSuggestedUsers()
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.loadStatus = .failed
                }
            } receiveValue: { [weak self] response in
                self?.users = response.users.sorted { $0.user.postCount * $0.numMutualFriends > $1.user.postCount * $1.numMutualFriends }
                self?.loadStatus = .loaded
            }.store(in: &cancelBag)
    }

    func follow(username: String, appState: AppState, viewState: GlobalViewState) {
        appState.followUser(username: username)
            .sink { completion in
                if case .failure = completion {
                    viewState.setError("Could not follow user")
                }
            } receiveValue: { [weak self] response in
                self?.handleFollowResponse(for: username, response: response)
            }.store(in: &cancelBag)
    }

    func unfollow(username: String, appState: AppState, viewState: GlobalViewState) {
        appState.unfollowUser(username: username)
            .sink { completion in
                if case .failure = completion {
                    viewState.setError("Could not unfollow user")
                }
            } receiveValue: { [weak self] response in
                self?.handleFollowResponse(for: username, response: response)
            }.store(in: &cancelBag)
    }

    private func handleFollowResponse(for username: String, response: FollowUserResponse) {
        if response.followed {
            followedUsernames.insert(username)
        } else {
            followedUsernames.remove(username)
        }
        if let followerCount = response.followers,
           let i = self.users.firstIndex(where: { $0.user.username == username }) {
            self.users[i].user.followerCount = followerCount
        }
    }
}

private struct SuggestedUserCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @ObservedObject var viewModel: SuggestedUserCarouselViewModel

    var navigate: (NavDestination) -> Void
    var item: SuggestedUserItem

    var user: PublicUser {
        item.user
    }

    var isFollowed: Bool {
        viewModel.isFollowed(user.username)
    }

    var followType: FollowButtonType {
        isFollowed ? .unfollow : .follow
    }

    var width: CGFloat {
        (UIScreen.main.bounds.width - 8) / 3
    }

    @ViewBuilder var profilePicture: some View {
        URLImage(
            url: user.profilePictureUrl,
            loading: Image(systemName: "person.crop.circle"),
            thumbnail: true
        )
        .foregroundColor(.gray)
        .frame(width: 60, height: 60)
        .cornerRadius(30)
    }

    @ViewBuilder var followButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if isFollowed {
                viewModel.unfollow(username: user.username, appState: appState, viewState: viewState)
            } else {
                viewModel.follow(username: user.username, appState: appState, viewState: viewState)
            }
        } label: {
            Group {
                Text(followType.text)
            }
            .font(.system(size: 12))
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .foregroundColor(followType.foregroundColor)
            .background(followType.backgroundColor)
            .cornerRadius(2)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(followType.foregroundColor, lineWidth: followType.hasBorder ? 1 : 0)
            )
        }
    }

    var body: some View {
        Button {
            navigate(.profile(user: user))
        } label: {
            VStack {
                profilePicture
                Text(user.username).font(.system(size: 12)).bold().lineLimit(1)
                Text(user.fullName).font(.system(size: 12)).lineLimit(1)
                followButton.padding(.horizontal)
                Text("mutual friend".plural(item.numMutualFriends)).font(.caption)
            }
            .frame(width: width, height: width * 1.4)
            .background(Color("foreground").opacity(0.1))
            .cornerRadius(2)
        }.buttonStyle(NoButtonStyle())
    }
}
