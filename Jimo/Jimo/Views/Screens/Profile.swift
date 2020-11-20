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
            URLImage(url: user.profilePicture, loading: defaultImage, failure: defaultImage)
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
    @ObservedObject var profileVM: ProfileVM
    
    func refresh() {
        profileVM.refresh()
    }
    
    private var navBody: AnyView {
        if let user = profileVM.user {
            let view = VStack {
                ProfileHeaderView(user: user)
                ProfileStatsView(user: user)
                FeedItem(name: profileVM.getName(user: user), placeName: "Kai's Hotdogs", region: "New York", timeSincePost: "8 min", content: "Soo good i love it", likeCount: 420, commentCount: 69)
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
            .navigationBarTitle("Profile", displayMode: .inline)
        }
    }
}

struct Profile_Previews: PreviewProvider {
    static var previews: some View {
        Profile(profileVM: ProfileVM(appVM: LocalVM(), username: "gautam"))
    }
}
