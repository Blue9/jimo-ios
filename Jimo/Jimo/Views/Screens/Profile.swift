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
    
    var isCurrentUser: Bool {
        guard case let .user(currentUser) = appState.currentUser else {
            return false
        }
        return user.username == currentUser.username
    }
    
    let defaultImage: Image = Image(systemName: "person.crop.circle")
    
    var name: String {
        user.firstName + " " + user.lastName
    }
    
    var body: some View {
        HStack(alignment: .top) {
            URLImage(url: user.profilePictureUrl, loading: defaultImage, failure: defaultImage)
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80, alignment: .center)
                .font(Font.title.weight(.light))
                .foregroundColor(.gray)
                .background(Color.white)
                .cornerRadius(50)
                .padding(.trailing)
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.system(size: 18))
                    .bold()
                    .minimumScaleFactor(0.5)
                    .frame(height: 25)
                Text("@" + user.username)
                    .frame(height: 25)
                    .font(.system(size: 14))
                    .padding(.bottom, 5)
                
                if isCurrentUser {
                    Spacer().frame(height: 30)
                } else if !profileVM.loadedRelation {
                    Text("Loading...")
                        .padding(5)
                        .font(.system(size: 14))
                        .background(Color.white)
                        .cornerRadius(10)
                        .foregroundColor(.gray)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                        .frame(height: 30)
                } else if profileVM.relationToUser == .following {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        profileVM.unfollowUser(username: user.username, appState: appState, viewState: viewState)
                    }) {
                        Text("Unfollow")
                            .padding(5)
                            .font(.system(size: 14))
                            .background(Color.white)
                            .cornerRadius(10)
                            .foregroundColor(.gray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    }.frame(height: 30)
                } else if profileVM.relationToUser == .blocked {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        profileVM.unblockUser(username: user.username, appState: appState, viewState: viewState)
                    }) {
                        Text("Unblock")
                            .padding(5)
                            .font(.system(size: 14))
                            .background(Color.red)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }.frame(height: 30)
                } else {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        profileVM.followUser(username: user.username, appState: appState, viewState: viewState)
                    }) {
                        Text("Follow")
                            .padding(5)
                            .font(.system(size: 14))
                            .background(Color.blue)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }.frame(height: 30)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 20)
    }
}

struct ProfileStatsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    
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
                Text(String(user.postCount))
                Text("Posts")
            }
            .frame(width: 80)
            Spacer()
            Button(action: { showFollowers.toggle() }) {
                VStack {
                    Text(String(user.followerCount))
                    Text("Followers")
                }
            }
            .frame(width: 80)
            Spacer()
            Button(action: { showFollowing.toggle()} ) {
                VStack {
                    Text(String(user.followingCount))
                    Text("Following")
                }
            }
            .frame(width: 80)
        }
        .padding(.horizontal, 40)
        .background(
            NavigationLink(destination: FollowFeed(navTitle: "Followers", type: .followers, username: user.username)
                            .environmentObject(appState)
                            .environmentObject(globalViewState)
                            .environment(\.backgroundColor, backgroundColor), isActive: $showFollowers) {}
        )
        .background(
            NavigationLink(destination: FollowFeed(navTitle: "Following", type: .following, username: user.username)
                            .environmentObject(appState)
                            .environmentObject(globalViewState)
                            .environment(\.backgroundColor, backgroundColor), isActive: $showFollowing) {}
        )
    }
}

struct Profile: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    @StateObject var profileVM = ProfileVM()
    
    let initialUser: User
    
    var username: String {
        initialUser.username
    }
    
    @State private var showUserOptions = false
    @State private var confirmBlockUser = false
    
    var profileBody: some View {
        ASCollectionView {
            ASCollectionViewSection(id: 0) {
                VStack {
                    ProfileHeaderView(profileVM: profileVM, initialUser: initialUser)
                    ProfileStatsView(profileVM: profileVM, initialUser: initialUser)
                }
                .padding(.bottom, 10)
            }
            
            ASCollectionViewSection(id: 1, data: profileVM.posts) { post, _ in
                FeedItemV2(post: post)
                    .frame(width: UIScreen.main.bounds.width)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            ASCollectionViewSection(id: 2) {
                Group {
                    if profileVM.loadStatus == .success {
                        Divider()
                        
                        ProgressView()
                            .opacity(profileVM.loadingMore ? 1 : 0)
                        
                        Text("You've reached the end!")
                            .padding()
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
        .shouldScrollToAvoidKeyboard(false)
        .layout {
            .list(itemSize: .estimated(200))
        }
        .animateOnDataRefresh(false)
        .alwaysBounceVertical(true)
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
        .background(backgroundColor)
        .ignoresSafeArea(.keyboard, edges: .all)
    }
    
    var body: some View {
        profileBody
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
    @Environment(\.backgroundColor) var backgroundColor
    
    let initialUser: User
    
    var body: some View {
        Profile(initialUser: initialUser)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor(UIColor(backgroundColor))
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    NavTitle("Profile")
                }
            })
    }
}

struct Profile_Previews: PreviewProvider {
    static let api = APIClient()
    static let appState = AppState(apiClient: api)

    static let user = PublicUser(
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
