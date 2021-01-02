//
//  PostModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/1/21.
//

import SwiftUI

enum FeedState: Equatable {
    case initializing
    case success
    case failure(RequestError)
}

class PostModel: ObservableObject {
    let model: AppModel
    @Published var feedState: FeedState
    @Published var feed: [Post]
    @Published var myPosts: [Post]
    
    init(model: AppModel, state: FeedState = .initializing, feed: [Post] = [], myPosts: [Post] = []) {
        self.model = model
        self.feedState = state
        self.feed = feed
        self.myPosts = myPosts
    }
    
    func refreshFeed(then: @escaping (RequestError?) -> Void) {
        model.refreshFeed(onComplete: { posts, error in
            if let posts = posts {
                DispatchQueue.main.async {
                    self.feedState = .success
                    self.feed = posts
                    then(error)
                }
            } else {
                DispatchQueue.main.async {
                    self.feedState = .failure(error ?? .unknownError) // error won't be nil but just in case
                    then(error)
                }
            }
        })
    }
    
    func createPost(_ request: CreatePostRequest, then: @escaping (RequestError?) -> Void) {
        model.createPost(request, onComplete: { (post, error) in
            if let post = post {
                DispatchQueue.main.async {
                    self.feed.insert(post, at: 0)
                    self.myPosts.insert(post, at: 0)
                    then(error)
                }
            } else {
                DispatchQueue.main.async {
                    then(error)
                }
            }
        })
    }
}
