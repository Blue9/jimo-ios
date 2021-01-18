//
//  FeedItem.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/8/20.
//

import SwiftUI

struct FeedItemLikes: View {
    @ObservedObject var allPosts: AllPosts
    @ObservedObject var feedItemVM: FeedItemVM
    
    private var showFilledHeart: Bool {
        (post.liked || feedItemVM.liking) && !feedItemVM.unliking
    }
    
    private var likeCount: Int {
        let inc = feedItemVM.liking ? 1 : 0
        let dec = feedItemVM.unliking ? 1 : 0
        return post.likeCount + inc - dec
    }
    
    var post: Post {
        // TODO maybe avoid "!"?
        allPosts.posts[feedItemVM.postId]!
    }
    
    var body: some View {
        if likeCount > 0 {
            Text(String(likeCount))
                .font(.subheadline)
        }

        if showFilledHeart {
            Button(action: { feedItemVM.unlikePost() }) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
            }
        } else {
            Button(action: { feedItemVM.likePost() }) {
                Image(systemName: "heart")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
            }
        }
    }
}

struct FeedItem: View {
    @EnvironmentObject var appState: AppState
    
    @State private var showPostOptions = false
    
    let formatter = RelativeDateTimeFormatter()
    /// If true, the full content is shown and is not tappable. This is used for the view post screen.
    var fullPost = false
    var allPosts: AllPosts
    var feedItemVM: FeedItemVM
    
    private func deletePost() {
        print("Delete post")
    }
    
    var post: Post {
        // TODO maybe avoid "!"?
        allPosts.posts[feedItemVM.postId]!
    }
    
    var isMyPost: Bool {
        if case let .user(user) = appState.currentUser {
            return user.username == post.user.username
        }
        // Should never be here since user should be logged in
        return false
    }
    
    var profileView: some View {
        Profile(profileVM: ProfileVM(appState: appState, user: post.user))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    NavTitle("Profile")
                }
            })
    }
    
    var fullPostView: some View {
        ViewPost(postId: feedItemVM.postId)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .principal) {
                    NavTitle("View Post")
                }
            })
    }
    
    var postContent: some View {
        let content = VStack(alignment: .leading) {
            Text(post.content)
                .padding(.top, 10)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, minHeight: 10, maxHeight: fullPost ? .infinity : 64, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            
            if let image = post.imageUrl {
                URLImage(url: image,
                         loading: Image(systemName: "rectangle.fill"))
                    .scaledToFill()
                    .font(.system(size: 1, weight: .ultraLight))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .cornerRadius(0)
                    .contentShape(Rectangle())
            }
        }
        
        if !fullPost {
            return AnyView(
                NavigationLink(destination: fullPostView) {
                    content.background(Color.white)
                }
                .buttonStyle(PlainButtonStyle()))
        } else {
            return AnyView(content)
        }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .frame(height: 32)
                .foregroundColor(Color(post.category))
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    
                    NavigationLink(destination: profileView) {
                        URLImage(
                            url: post.user.profilePictureUrl,
                            loading: Image(systemName: "person.crop.circle"),
                            failure: Image(systemName: "person.crop.circle"))
                            .foregroundColor(.gray)
                            .background(Color.white)
                            .font(.system(size: 16, weight: .ultraLight))
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60, alignment: .center)
                            .cornerRadius(30)
                            .padding(.trailing, 6)
                            .padding(.top, 4)
                    }
                    .buttonStyle(DefaultButtonStyle())
                    
                    VStack(alignment: .leading) {
                        HStack {
                            NavigationLink(destination: profileView) {
                                Text(post.user.firstName + " " + post.user.lastName)
                                    .font(.title3)
                                    .bold()
                                    .frame(height: 26)
                                    .padding(.trailing, 10)
                            }
                            .foregroundColor(.black)
                            .buttonStyle(DefaultButtonStyle())
                            
                            Spacer()
                            
                            Button(action: { self.showPostOptions = true }) {
                                Image(systemName: "ellipsis")
                                    .font(.subheadline)
                                    .frame(width: 26, height: 26)
                                    .padding(.trailing)
                                    .foregroundColor(.black)
                            }
                        }
                        HStack {
                            Text(post.place.name)
                        }
                        .font(.footnote)
                        .offset(y: 6)
                    }
                }
                .padding(.leading)
                
                postContent
                
                HStack {
                    Text(formatter.localizedString(for: post.createdAt, relativeTo: Date()))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    FeedItemLikes(allPosts: allPosts, feedItemVM: feedItemVM)
                }
                .padding(.top, 4)
                .padding(.horizontal)
                
                Divider()
            }
            .padding(.top, 4)
        }
        .actionSheet(isPresented: $showPostOptions) {
            ActionSheet(
                title: Text("Post options"),
                buttons: isMyPost ? [
                    .destructive(Text("Delete"), action: self.deletePost),
                    .cancel()
                ] : [
                    .cancel()
                ])
        }
    }
}

struct FeedItem_Previews: PreviewProvider {
    static let api = APIClient()
    static let appState = AppState(apiClient: api)
    
    static let allPosts: AllPosts = {
        let all = AllPosts()
        all.posts[post.postId] = post
        return all
    }()
    
    static let post = Post(
        postId: "test",
        user: PublicUser(
            username: "john",
            firstName: "Johnjohnjohn",
            lastName: "JohnjohnjohnJohnjohnjohnJohnjohnjohn",
            profilePictureUrl: "https://i.imgur.com/ugITQw2.jpg",
            postCount: 100,
            followerCount: 1000000,
            followingCount: 1),
        place: Place(placeId: "place", name: "Kai's Hotdogs This is a very very very very long place name", location: Location(coord: .init(latitude: 0, longitude: 0))),
        category: "food",
        content: "Wow! I really really really like this place. This place is so so so very very good. I really really really like this place. This place is so so so very very good.",
        imageUrl: "https://i.imgur.com/ugITQw2.jpg",
        createdAt: Date(),
        likeCount: 10,
        liked: false,
        customLocation: nil)
    
    static var previews: some View {
        FeedItem(allPosts: allPosts, feedItemVM: FeedItemVM(appState: appState, postId: post.postId))
            .environmentObject(api)
            .environmentObject(appState)
    }
}
