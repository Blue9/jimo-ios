//
//  Profile.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/7/20.
//

import SwiftUI


struct ProfileHeaderView: View {
    var user: User
    let defaultImage: Image = Image(systemName: "person.crop.circle")
    
    var name: String {
        user.firstName + " " + user.lastName
    }
    
    var body: some View {
        HStack {
            URLImage(url: user.profilePictureUrl, loading: defaultImage, failure: defaultImage)
                .frame(width: 80, height: 80, alignment: .center)
                .font(Font.title.weight(.ultraLight))
                .cornerRadius(50)
                .padding(.trailing)
            VStack(alignment: .leading) {
                Text(name)
                    .fontWeight(.bold)
                Text("@" + user.username)
            }
            Spacer()
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 20)
    }
}

struct ProfileStatsView: View {
    var user: User
    
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
    @ObservedObject var profileVM: ProfileVM
    
    var body: some View {
        if let posts = profileVM.posts {
            ForEach(posts) { post in
                FeedItem(post: post)
            }
            Text("You've reached the end!")
        } else {
            Text("Failed to load posts")
        }
    }
}

private struct PlaceholderText: View {
    var text: String
    
    var body: some View {
        return GeometryReader { geometry in
            Text(text)
                .fontWeight(.medium)
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .center)
        }
    }
}


struct Profile: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject var profileVM: ProfileVM
    
    private var navBody: AnyView {
        if let user = profileVM.user {
            let view = VStack {
                ProfileHeaderView(user: user)
                ProfileStatsView(user: user)
                ProfilePosts(profileVM: profileVM)
            }
            .padding(.top)
            return AnyView(view)
        } else if profileVM.failedToLoad {
            return AnyView(PlaceholderText(text: "Failed to load profile"))
        } else {
            return AnyView(PlaceholderText(text: "Loading profile"))
        }
    }
    
    var body: some View {
        NavigationView {
            RefreshableScrollView(refreshing: $profileVM.refreshing) {
                navBody
            }
            //.navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    NavTitle("Profile")
                }
                ToolbarItem(placement: .navigationBarTrailing, content: {
                    Button("Sign out") {
                        withAnimation(.default, {
                            model.signOut()
                        })
                    }
                })
            })
        }
    }
}

struct Profile_Previews: PreviewProvider {
    static let sessionStore = SessionStore()
    static let model = AppModel()
    
    static var previews: some View {
        Profile(profileVM: ProfileVM(model: model, username: "gautam"))
            .environmentObject(model)
            .environmentObject(PostModel(model: model))
    }
}
