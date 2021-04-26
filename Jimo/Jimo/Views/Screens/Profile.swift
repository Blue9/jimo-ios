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
    @ObservedObject var profileVM: ProfileVM
    
    var user: User {
        profileVM.user
    }
    
    var isCurrentUser: Bool {
        guard case let .user(currentUser) = appState.currentUser else {
            return false
        }
        return profileVM.user.username == currentUser.username
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
                .id(user.profilePictureUrl)
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(Font.custom(Poppins.medium, size: 18))
                    .fontWeight(.semibold)
                    .frame(height: 25)
                Text("@" + user.username)
                    .frame(height: 25)
                    .padding(.bottom, 5)
                
                if isCurrentUser {
                    Spacer().frame(height: 30)
                } else if !profileVM.loadedRelation {
                    Text("Loading...")
                        .padding(5)
                        .font(Font.custom(Poppins.regular, size: 14))
                        .background(Color.white)
                        .cornerRadius(10)
                        .foregroundColor(.gray)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 1)
                        )
                } else if profileVM.relationToUser == .following {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        profileVM.unfollowUser()
                    }) {
                        Text("Unfollow")
                            .padding(5)
                            .font(Font.custom(Poppins.regular, size: 14))
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
                        profileVM.unblockUser()
                    }) {
                        Text("Unblock")
                            .padding(5)
                            .font(Font.custom(Poppins.regular, size: 14))
                            .background(Color.red)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }.frame(height: 30)
                } else {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        profileVM.followUser()
                    }) {
                        Text("Follow")
                            .padding(5)
                            .font(Font.custom(Poppins.regular, size: 14))
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
    @ObservedObject var profileVM: ProfileVM
    
    var user: User {
        profileVM.user
    }
    
    var body: some View {
        HStack {
            VStack {
                Text(String(user.postCount))
                Text("Posts")
            }
            .frame(width: 80)
            Spacer()
            VStack {
                Text(String(user.followerCount))
                Text("Followers")
            }
            .frame(width: 80)
            Spacer()
            VStack {
                Text(String(user.followingCount))
                Text("Following")
            }
            .frame(width: 80)
        }
        .padding(.horizontal, 40)
    }
}

struct Profile: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    @StateObject var profileVM: ProfileVM
    
    private var section: ASCollectionViewSection<Int> {
        ASCollectionViewSection(id: 2, data: profileVM.posts, dataID: \.self) { postId, _ in
            if postId == "" {
                EmptyView()
            } else {
                FeedItem(feedItemVM: FeedItemVM(appState: appState,
                                                viewState: globalViewState, postId: postId,
                                                onDelete: { profileVM.removePost(postId: postId) }))
                    .frame(width: UIScreen.main.bounds.width)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
    
    var profileBody: some View {
        ASCollectionView {
            section
                .sectionHeader {
                    VStack {
                        ProfileHeaderView(profileVM: profileVM)
                        ProfileStatsView(profileVM: profileVM)
                    }
                    .padding(.bottom, 10)
                }
            ASCollectionViewSection(id: 3) {
                Group {
                    if profileVM.loadStatus == .success {
                        Divider()
                        Text("You've reached the end!")
                            .padding()
                    } else if profileVM.loadStatus == .failed {
                        Text("Failed to load posts")
                            .padding()
                    } else { // notInitialized
                        ProgressView()
                            .appear {
                                profileVM.loadFollowStatusV2()
                                profileVM.loadPosts()
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
        .animateOnDataRefresh(true)
        .alwaysBounceVertical(true)
        .scrollIndicatorsEnabled(horizontal: false, vertical: false)
        .onPullToRefresh { onFinish in
            profileVM.refresh(onFinish: onFinish)
        }
        .font(Font.custom(Poppins.medium, size: 15))
        .background(backgroundColor)
        .appear {
            profileVM.removeDeletedPosts()
            /// Similar to feed:
            /// This is a hack that forces the collection view to refresh. Without this, if a feed item resizes
            /// itself (e.g. when editing), its bounding box won't refresh, so the feed item's layout will get messed up.
            /// There is also `.shouldRecreateLayoutOnStateChange()` which works but is noticeably slower and doesn't look as nice
            profileVM.posts.append("")
        }
        .ignoresSafeArea(.keyboard, edges: .all)
    }
    
    @State private var showUserOptions = false
    @State private var confirmBlockUser = false
    
    var body: some View {
        profileBody
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !profileVM.isCurrentUser {
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
                            .destructive(Text("Unblock"), action: { profileVM.unblockUser() }),
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
                    message: Text("Block @\(profileVM.user.username)? They won't know you blocked them."),
                    primaryButton: .default(Text("Block")) { profileVM.blockUser() },
                    secondaryButton: .cancel()
                )
            }
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
        Profile(profileVM: ProfileVM(appState: appState, globalViewState: GlobalViewState(), user: user))
            .environmentObject(appState)
            .environmentObject(GlobalViewState())
    }
}
