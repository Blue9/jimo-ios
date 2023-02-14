//
//  Profile.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/7/20.
//

import SwiftUI

struct Profile: View {
    enum Destination: Hashable {
        case editProfile, submitFeedback, post(Post), followers(username: String), following(username: String)

        @ViewBuilder
        func view() -> some View {
            switch self {
            case .editProfile:
                EditProfile()
            case .submitFeedback:
                Feedback()
            case let .post(post):
                ViewPost(initialPost: post)
            case let .followers(username):
                FollowFeed(navTitle: "Followers", type: .followers, username: username)
            case let .following(username):
                FollowFeed(navTitle: "Following", type: .following, username: username)
            }
        }
    }

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @StateObject var profileVM = ProfileVM()

    let initialUser: PublicUser
    var editPost: ((Post) -> Void)?

    private let columns: [GridItem] = [
        GridItem(.flexible(minimum: 50), spacing: 2),
        GridItem(.flexible(minimum: 50), spacing: 2),
        GridItem(.flexible(minimum: 50), spacing: 2)
    ]

    @State private var showUserOptions = false
    @State private var confirmBlockUser = false
    @State private var navigationDestination: Destination?
    @State private var isShareSheetPresented = false

    var user: PublicUser {
        profileVM.user ?? initialUser
    }

    var username: String {
        user.username
    }

    @ViewBuilder
    var profileGrid: some View {
        RefreshableScrollView(spacing: 0) {
            ProfileHeaderView(
                profileVM: profileVM,
                shareProfile: { self.isShareSheetPresented = true },
                navigate: { self.navigationDestination = $0 },
                initialUser: initialUser
            ).padding(.bottom, 10)

            LazyVGrid(columns: columns, spacing: 2) {
                if profileVM.loadStatus == .success
                    && appState.me?.id == initialUser.id
                    && profileVM.posts.isEmpty {
                    createPostButton
                }

                ForEach(profileVM.posts) { post in
                    Button {
                        self.navigationDestination = .post(post)
                    } label: {
                        if let editPost = editPost {
                            PostGridCell(post: post)
                                .background(Color("background"))
                                .contextMenu {
                                    Button {
                                        editPost(post)
                                    } label: {
                                        Label("Edit", systemImage: "square.and.pencil")
                                    }
                                }
                        } else {
                            PostGridCell(post: post)
                        }
                    }
                }
            }
        } onRefresh: { onFinish in
            profileVM.refresh(username: username, appState: appState, viewState: viewState, onFinish: onFinish)
        } onLoadMore: {
            profileVM.loadMorePosts(username: username, appState: appState, viewState: viewState)
        }
        .sheet(isPresented: $isShareSheetPresented) {
            ActivityView(shareAction: .profile(user), isPresented: $isShareSheetPresented)
        }
        .font(.system(size: 15))
        .navigation(destination: $navigationDestination) {
            navigationDestination?.view()
        }
    }

    @ViewBuilder
    var createPostButton: some View {
        Button {
            Analytics.track(.profileNewPostTapped)
            viewState.createPostPresented = true
        } label: {
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    Rectangle()
                        .fill()
                        .foregroundColor(.gray)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                        .frame(width: geometry.size.width, height: geometry.size.width)
                }
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(2)

                Spacer().frame(height: 60)
            }
        }
    }

    var body: some View {
        profileGrid
            .appear {
                if profileVM.loadStatus == .notInitialized {
                    profileVM.refresh(username: username, appState: appState, viewState: viewState)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !profileVM.isCurrentUser(appState: appState, username: username) {
                        Button {
                            showUserOptions.toggle()
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    } else {
                        EmptyView()
                    }
                }
            }
            .actionSheet(isPresented: $showUserOptions) {
                if profileVM.relationToUser == .blocked {
                    return ActionSheet(
                        title: Text("Options"),
                        buttons: [
                            .destructive(Text("Unblock"), action: { profileVM.unblockUser(username: username, appState: appState, viewState: viewState) }),
                            .cancel()
                        ]
                    )
                } else {
                    return ActionSheet(
                        title: Text("Options"),
                        buttons: [
                            .destructive(Text("Block"), action: { confirmBlockUser = true }),
                            .cancel()
                        ]
                    )
                }
            }
            .alert(isPresented: $confirmBlockUser) {
                Alert(
                    title: Text("Confirm"),
                    message: Text("Block @\(username)? They won't know you blocked them."),
                    primaryButton: .default(Text("Block")) { profileVM.blockUser(username: username, appState: appState, viewState: viewState) },
                    secondaryButton: .cancel()
                )
            }
    }
}

struct ProfileScreen: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var createPostVM = CreatePostVM()
    @State private var showCreatePostSheet = false
    var initialUser: PublicUser

    var body: some View {
        Profile(
            initialUser: initialUser,
            editPost: appState.me?.id == initialUser.id ? self.editPost(_:) : nil
        )
        .sheet(isPresented: $showCreatePostSheet, onDismiss: createPostVM.resetAll) {
            CreatePostWithModel(createPostVM: createPostVM, presented: $showCreatePostSheet)
        }
        .background(Color("background"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(Color("background")))
        .navigationTitle(Text("Profile"))
        .trackScreen(.profileView)
    }

    func editPost(_ post: Post) {
        createPostVM.resetAll()
        createPostVM.initAsEditor(post)
        showCreatePostSheet = true
    }
}

private struct ProfileHeaderView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState

    @ObservedObject var profileVM: ProfileVM

    @State private var showCreatePostView = false

    var shareProfile: () -> Void
    var navigate: (Profile.Destination?) -> Void

    let initialUser: User

    var user: User {
        profileVM.user ?? initialUser
    }

    let defaultImage: Image = Image(systemName: "person.crop.circle")

    var name: String {
        user.firstName + " " + user.lastName
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                URLImage(url: user.profilePictureUrl, loading: defaultImage)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80, alignment: .center)
                    .font(Font.title.weight(.light))
                    .foregroundColor(.gray)
                    .background(Color.white)
                    .cornerRadius(40)
                    .padding(.trailing)
                ProfileStatsView(profileVM: profileVM, initialUser: initialUser, navigate: navigate)
            }.padding(.leading, 20)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(user.username)
                        .font(.system(size: 15))
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(name)
                        .font(.system(size: 15))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                .foregroundColor(Color("foreground"))
                .frame(width: 120, alignment: .topLeading)
                .frame(minHeight: 40)

                Spacer()

                ProfileActionButtonView(
                    profileVM: profileVM,
                    initialUser: initialUser,
                    shareProfile: shareProfile,
                    navigate: navigate
                )

                // Cannot share blocked user profile
                if profileVM.relationToUser != .blocked {
                    ShareButtonView(shareAction: .profile(user))
                        .offset(y: -2)
                        .padding(.horizontal)
                } else {
                    Spacer().frame(width: 25)
                }
            }.padding(.leading, 20)

            if profileVM.isCurrentUser(appState: appState, username: user.username) {
                currentUserHeader
                    .padding(.top)
            }
        }
        .background(Color("background"))
    }

    @ViewBuilder
    fileprivate func headerButtonText(
        _ dest: Profile.Destination,
        _ text: String,
        _ buttonImage: String? = nil
    ) -> some View {
        Button {
            self.navigate(dest)
        } label: {
            HStack(spacing: 3) {
                if let buttonImage = buttonImage {
                    Image(systemName: buttonImage)
                        .font(.system(size: 12))
                }
                Text(text)
                    .font(.caption)
                    .bold()
            }
            .padding(.leading)
            .padding(.trailing)
            .padding(.vertical, 8)
            .background(Color("foreground").opacity(0.15))
            .cornerRadius(2)
        }
    }

    @ViewBuilder
    var currentUserHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                headerButtonText(.editProfile, "Edit profile", "square.and.pencil")
                headerButtonText(.submitFeedback, "Submit feedback", "exclamationmark.bubble")
                headerButtonText(.submitFeedback, "Report a problem", "exclamationmark.triangle")
            }
            .padding(.horizontal, 20)
        }
    }
}

struct ProfileStatsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState

    @ObservedObject var profileVM: ProfileVM

    let initialUser: User

    var navigate: (Profile.Destination?) -> Void

    var user: User {
        profileVM.user ?? initialUser
    }

    var body: some View {
        HStack {
            VStack {
                Text(user.postCount.kFormatted).bold()
                Text("Posts")
            }
            .padding(.leading, 15)
            .padding(.trailing, 10)
            Spacer()

            Button { navigate(.followers(username: user.username)) } label: {
                VStack {
                    Text(user.followerCount.kFormatted).bold()
                    Text("Followers")
                }
            }
            .padding(.trailing, 10)
            Spacer()

            Button { navigate(.following(username: user.username)) } label: {
                VStack {
                    Text(user.followingCount.kFormatted).bold()
                    Text("Following")
                }
            }
            Spacer()
        }
        .font(.system(size: 15))
        .foregroundColor(Color("foreground"))
    }
}

struct ProfileActionButtonView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @ObservedObject var profileVM: ProfileVM

    let initialUser: User
    let shareProfile: () -> Void
    let navigate: (Profile.Destination) -> Void

    var user: User {
        profileVM.user ?? initialUser
    }

    var isCurrentUser: Bool {
        guard case let .user(currentUser) = appState.currentUser else {
            return false
        }
        return user.username == currentUser.username
    }

    var body: some View {
        VStack {
            if isCurrentUser {
                ProfileButton(textType: .share) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    shareProfile()
                }
            } else if !profileVM.loadedRelation {
                Text("Loading...")
                    .padding(10)
                    .font(.system(size: 15))
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(2)
                    .foregroundColor(.gray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .frame(height: 30)
            } else if profileVM.relationToUser == .following {
                ProfileButton(textType: .unfollow) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    profileVM.unfollowUser(username: user.username, appState: appState, viewState: viewState)
                }
            } else if profileVM.relationToUser == .blocked {
                ProfileButton(textType: .unblock) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    profileVM.unblockUser(username: user.username, appState: appState, viewState: viewState)
                }
            } else {
                ProfileButton(textType: .follow) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    profileVM.followUser(username: user.username, appState: appState, viewState: viewState)
                }
            }
        }
        .padding(.leading)
    }
}

private enum TextType {
    case follow, unfollow, unblock, loading, share

    var text: String {
        switch self {
        case .follow: return "Follow"
        case .unfollow: return "Unfollow"

        case .unblock: return "Unblock"
        case .loading: return "Loading..."
        case .share: return "Share my profile"
        }
    }

    var analyticsEvent: AnalyticsName? {
        switch self {
        case .follow: return .userFollowed
        case .unfollow: return .userUnfollowed
        case .unblock: return nil
        case .loading: return nil
        case .share: return .shareMyProfileTapped
        }
    }

    var backgroundColor: Color {
        switch self {
        case .loading, .unfollow: return .white
        case .unblock: return .red
        case .follow: return .blue
        case .share: return .blue
        }
    }

    var foregroundColor: Color {
        return buttonHasBorder ? .gray : .white
    }

    var buttonHasBorder: Bool {
        return backgroundColor == .white
    }
}

private struct ProfileButton: View {
    var textType: TextType
    var action: () -> Void

    var body: some View {
        Button {
            if let analyticsEvent = textType.analyticsEvent {
                Analytics.track(analyticsEvent)
            }
            action()
        } label: {
            Text(textType.text)
                .padding(Constants.TEXT_PADDING)
                .font(Constants.TEXT_FONT)
                .frame(maxWidth: .infinity)
                .background(textType.backgroundColor)
                .cornerRadius(Constants.TEXT_CORNER_RADIUS)
                .foregroundColor(textType.foregroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.TEXT_CORNER_RADIUS)
                        .stroke(textType.foregroundColor, lineWidth: textType.buttonHasBorder ? 1 : 0)
                )
                .frame(height: 30)
        }.frame(height: 30)
    }
}

extension ProfileButton {
    private struct Constants {
        static let TEXT_PADDING: CGFloat = 10
        static let TEXT_FONT = SwiftUI.Font.system(size: 15)
        static let TEXT_CORNER_RADIUS: CGFloat = 2
    }
}

fileprivate extension Int {
    var kFormatted: String {
        if self > 1000 {
            var n = Double(self)
            n = Double(floor(n / 100) / 10)
            return "\(n.description)K"
        }
        return "\(self)"
    }
}
