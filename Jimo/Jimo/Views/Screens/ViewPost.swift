//
//  ViewPost.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/5/21.
//

import SwiftUI

struct ViewPost: View {
    @EnvironmentObject var appState: AppState
    let postId: PostId

    var body: some View {
        ScrollView {
            FeedItem(feedItemVM: FeedItemVM(appState: appState, postId: postId), fullPost: true)
        }
    }
}


struct ViewPost_Previews: PreviewProvider {
    static let api = APIClient()
    static let appState: AppState = {
        let state = AppState(apiClient: api)
        state.allPosts.posts[post.postId] = post
        return state
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
        ViewPost(postId: post.postId)
            .environmentObject(api)
            .environmentObject(appState)
    }
}
