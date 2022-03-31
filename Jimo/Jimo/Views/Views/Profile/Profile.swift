//
//  Profile.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/7/20.
//

import SwiftUI
import ASCollectionView


struct ProfileHeaderView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    
    @ObservedObject var profileVM: ProfileVM
    
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
                ProfileStatsView(profileVM: profileVM, initialUser: initialUser)
            }
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
                FollowButtonView(profileVM: profileVM, initialUser: initialUser)
            }
        }
        .padding(.leading, 20)
        .background(Color("background"))
    }
}

struct ProfileStatsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @ObservedObject var profileVM: ProfileVM
    
    let initialUser: User
    
    @State private var showFollowers = false
    @State private var showFollowing = false
    
    var user: User {
        profileVM.user ?? initialUser
    }
    
    var body: some View {
        HStack {
            VStack {
                Text(String(user.postCount)).bold()
                Text("Places")
            }
            .padding(.leading, 15)
            .padding(.trailing, 10)
            Spacer()
            
            Button(action: { showFollowers.toggle() }) {
                VStack {
                    Text(String(user.followerCount)).bold()
                    Text("Followers")
                }
            }
            .padding(.trailing, 10)
            Spacer()
            
            Button(action: { showFollowing.toggle()} ) {
                VStack {
                    Text(String(user.followingCount)).bold()
                    Text("Following")
                }
            }
            Spacer()
        }
        .font(.system(size: 15))
        .foregroundColor(Color("foreground"))
        .background(
            NavigationLink(destination: FollowFeed(navTitle: "Followers", type: .followers, username: user.username)
                            .environmentObject(appState)
                            .environmentObject(globalViewState), isActive: $showFollowers) {}
        )
        .background(
            NavigationLink(destination: FollowFeed(navTitle: "Following", type: .following, username: user.username)
                            .environmentObject(appState)
                            .environmentObject(globalViewState), isActive: $showFollowing) {}
        )
    }
}

struct FollowButtonView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @ObservedObject var profileVM: ProfileVM
    
    let initialUser: User
    
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
                Spacer().frame(height: 30)
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
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    profileVM.unfollowUser(username: user.username, appState: appState, viewState: viewState)
                }) {
                    Text("Unfollow")
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
                }.frame(height: 30)
            } else if profileVM.relationToUser == .blocked {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    profileVM.unblockUser(username: user.username, appState: appState, viewState: viewState)
                }) {
                    Text("Unblock")
                        .padding(10)
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(2)
                        .foregroundColor(.white)
                }.frame(height: 30)
            } else {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    profileVM.followUser(username: user.username, appState: appState, viewState: viewState)
                }) {
                    Text("Follow")
                        .padding(10)
                        .font(.system(size: 15))
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(2)
                        .foregroundColor(.white)
                }.frame(height: 30)
            }
        }
        .padding(.horizontal)
    }
}

struct Profile: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @StateObject var profileVM = ProfileVM()
    
    let initialUser: User
    
    var username: String {
        initialUser.username
    }
    
    @State private var showUserOptions = false
    @State private var confirmBlockUser = false
    
    var profileGrid: some View {
        ASCollectionView {
            ASCollectionViewSection(id: 0) {
                ProfileHeaderView(profileVM: profileVM, initialUser: initialUser).padding(.bottom, 10)
            }
            
            ASCollectionViewSection(id: 1, data: profileVM.posts) { post, _ in
                GeometryReader { geometry in
                    NavigationLink(destination: ViewPost(post: post)) {
                        if let url = post.imageUrl {
                            URLImage(url: url, thumbnail: true)
                                .frame(maxWidth: .infinity)
                                .frame(width: geometry.size.width, height: geometry.size.width)
                        } else {
                            MapSnapshotView(post: post, width: (UIScreen.main.bounds.width - 6) / 3)
                                .frame(maxWidth: .infinity)
                                .frame(height: geometry.size.width)
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .background(Color(post.category))
                .cornerRadius(2)
            }
            
            ASCollectionViewSection(id: 2) {
                Group {
                    if profileVM.loadStatus == .success {
                        ProgressView()
                            .opacity(profileVM.loadingMore ? 1 : 0)
                    } else if profileVM.loadStatus == .failed {
                        Text("Failed to load posts")
                            .padding()
                    } else { // notInitialized
                        ProgressView()
                            .appear {
                                profileVM.loadRelation(username: username, appState: appState, viewState: viewState)
                                profileVM.loadPosts(username: username, appState: appState, viewState: viewState)
                            }
                    }
                }
                .padding(.top)
            }
        }
        .alwaysBounceVertical()
        .shouldScrollToAvoidKeyboard(false)
        .layout { sectionID in
            switch sectionID {
            case 1:
                return .grid(
                    layoutMode: .fixedNumberOfColumns(3),
                    itemSpacing: 2,
                    lineSpacing: 2,
                    itemSize: .absolute((UIScreen.main.bounds.width - 8) / 3),
                    sectionInsets: .init(top: 0, leading: 2, bottom: 0, trailing: 2)
                )
            default:
                return .list(itemSize: .estimated(200))
            }
        }
        .scrollIndicatorsEnabled(horizontal: false, vertical: false)
        .onPullToRefresh { onFinish in
            profileVM.refresh(username: username, appState: appState, viewState: viewState, onFinish: onFinish)
        }
        .onReachedBoundary { boundary in
            if boundary == .bottom {
                profileVM.loadMorePosts(username: username, appState: appState, viewState: viewState)
            }
        }
        .font(.system(size: 15))
        .ignoresSafeArea(.keyboard, edges: .all)
    }
    
    var body: some View {
        profileGrid
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
    let initialUser: User
    
    var body: some View {
        Profile(initialUser: initialUser)
            .background(Color("background"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor(UIColor(Color("background")))
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    NavTitle("Profile")
                }
            })
            .trackScreen(.profileView)
    }
}

struct Profile_Previews: PreviewProvider {
    static let api = APIClient()
    static let appState = AppState(apiClient: api)

    static let user = PublicUser(
        userId: "user-id",
        username: "john",
        firstName: "Johnjohnjohn",
        lastName: "JohnjohnjohnJohnjohnjohnJohnjohnjohn",
        profilePictureUrl: "https://i.imgur.com/ugITQw2.jpg",
        postCount: 100,
        followerCount: 1000000,
        followingCount: 1)
    
    static var previews: some View {
        Profile(initialUser: user)
            .environmentObject(appState)
            .environmentObject(GlobalViewState())
    }
}
