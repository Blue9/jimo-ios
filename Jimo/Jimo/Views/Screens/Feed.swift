//
//  Feed.swift
//  Jimo
//
//  Created by Gautam Mekkat on 12/13/20.
//

import SwiftUI

enum FeedState {
    case loading, success, failure
}

class FeedModel: ObservableObject {
    @Published var posts: [Post] = []
    
    @Published var scrollViewRefresh = false {
        didSet {
            if oldValue == false && scrollViewRefresh == true {
                self.refreshFeed()
            }
        }
    }
    @Published var state: FeedState = .loading
    let model: AppModel
    
    init(model: AppModel) {
        self.model = model
    }
    
    func refreshFeed() {
        model.getFeed(onComplete: { posts, error in
            DispatchQueue.main.async {
                self.scrollViewRefresh = false
                if let posts = posts {
                    print("Number of posts", posts.count)
                    self.posts = posts
                    self.state = .success
                } else {
                    // TODO - handle error since non-nil
                    print(error.debugDescription)
                    self.state = .failure
                }
            }
        })
    }
}

struct FeedBody: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject var feedModel: FeedModel
    
    var body: some View {
        if feedModel.state == .loading {
            ProgressView()
                .onAppear {
                    print("On appear")
                    feedModel.refreshFeed()
                }
        } else {
            RefreshableScrollView(refreshing: $feedModel.scrollViewRefresh) {
                ForEach(feedModel.posts) { post in
                    FeedItem(name: post.user.firstName, profilePicture: post.user.profilePictureUrl, placeName: "Place name", region: "Region name", timeSincePost: "8 min", content: post.content, likeCount: post.likeCount, commentCount: post.commentCount)
                }
                Text("You've reached the end!")
            }
        }
    }
}

struct Feed: View {
    @EnvironmentObject var model: AppModel
    @ObservedObject var feedModel: FeedModel

    var body: some View {
        NavigationView {
            FeedBody(feedModel: feedModel)
                .navigationTitle("Feed")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct Feed_Previews: PreviewProvider {
    static let model = AppModel()
    static var previews: some View {
        Feed(feedModel: FeedModel(model: model)).environmentObject(model)
    }
}
