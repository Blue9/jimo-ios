//
//  DiscoverViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/8/21.
//

import Foundation
import Combine

class DiscoverViewModel: ObservableObject {
    let nc = NotificationCenter.default
    
    @Published var posts: [Post] = []
    @Published var initialized = false
    
    private var loadFeedCancellable: Cancellable?
    
    init() {
        nc.addObserver(self, selector: #selector(postLiked), name: PostPublisher.postLiked, object: nil)
        nc.addObserver(self, selector: #selector(postDeleted), name: PostPublisher.postDeleted, object: nil)
    }
    
    @objc private func postLiked(notification: Notification) {
        let like = notification.object as! PostLikePayload
        let postIndex = posts.indices.first(where: { posts[$0].postId == like.postId })
        if let i = postIndex {
            posts[i].likeCount = like.likeCount
            posts[i].liked = like.liked
        }
    }
    
    @objc private func postDeleted(notification: Notification) {
        let postId = notification.object as! PostId
        posts.removeAll(where: { $0.postId == postId })
    }
    
    func loadDiscoverPage(appState: AppState, onFinish: OnFinish? = nil) {
        loadFeedCancellable = appState.discoverFeed()
            .sink(receiveCompletion: { [weak self] completion in
                self?.initialized = true
                onFinish?()
                if case let .failure(error) = completion {
                    print("Error when loading posts", error)
                }
            }, receiveValue: { [weak self] posts in
                self?.posts = posts
            })
    }
}
