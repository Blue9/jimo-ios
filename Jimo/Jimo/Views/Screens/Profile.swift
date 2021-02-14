//
//  Profile.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/7/20.
//

import SwiftUI


struct ProfileHeaderView: View {
    @ObservedObject var profileVM: ProfileVM
    
    var user: User {
        profileVM.user
    }
    
    let defaultImage: Image = Image(systemName: "person.crop.circle")
    
    var name: String {
        user.firstName + " " + user.lastName
    }
    
    var body: some View {
        HStack {
            URLImage(url: user.profilePictureUrl, loading: defaultImage, failure: defaultImage)
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80, alignment: .center)
                .font(Font.title.weight(.ultraLight))
                .foregroundColor(.gray)
                .background(Color.white)
                .cornerRadius(50)
                .padding(.trailing)
                .id(user.profilePictureUrl)
            VStack(alignment: .leading) {
                Text(name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(height: 30)
                Text("@" + user.username)
                    .frame(height: 30)
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
                    .bold()
                Text("Posts")
                    .bold()
            }
            .frame(width: 80)
            Spacer()
            VStack {
                Text(String(user.followerCount))
                    .bold()
                Text("Followers")
                    .bold()
            }
            .frame(width: 80)
            Spacer()
            VStack {
                Text(String(user.followingCount))
                    .bold()
                Text("Following")
                    .bold()
            }
            .frame(width: 80)
        }
        .padding(.horizontal, 40)
    }
}

struct ProfilePosts: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @ObservedObject var profileVM: ProfileVM
    
    var body: some View {
        if let posts = profileVM.posts {
            VStack {
                ForEach(posts, id: \.self) { postId in
                    FeedItem(feedItemVM: FeedItemVM(appState: appState, viewState: globalViewState, postId: postId))
                }
                Text("You've reached the end!")
                    .padding()
            }
        } else if profileVM.failedToLoadPosts {
            Text("Failed to load posts")
                .padding()
        } else {
            ProgressView()
                .onAppear {
                    profileVM.loadPosts()
                }
        }
    }
}


struct Profile: View {
    @StateObject var profileVM: ProfileVM
    
    var body: some View {
        RefreshableScrollView(refreshing: $profileVM.refreshing) {
            VStack {
                ProfileHeaderView(profileVM: profileVM)
                ProfileStatsView(profileVM: profileVM)
                ProfilePosts(profileVM: profileVM)
            }
            .padding(.top)
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
