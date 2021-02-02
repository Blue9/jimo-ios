//
//  FeedItemVM.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/10/21.
//

import SwiftUI
import Combine

class FeedItemVM: ObservableObject {
    let appState: AppState
    let postId: PostId
    
    @Published var liking = false
    @Published var unliking = false
    @Published var deleting = false
    @Published var post: Post?
    
    var updatePostCancellable: Cancellable? = nil
    var likeCancellable: Cancellable? = nil
    var unlikeCancellable: Cancellable? = nil
    var deleteCancellable: Cancellable? = nil
    
    init(appState: AppState, postId: PostId) {
        self.appState = appState
        self.postId = postId
        self.post = appState.allPosts.posts[postId]
    }
    
    func listenToPostUpdates() {
        print("Listening to post updates")
        updatePostCancellable = appState.allPosts.$posts
            .sink(receiveValue: { [weak self] posts in
                guard let self = self else {
                    return
                }
                if self.post != posts[self.postId] {
                    self.post = posts[self.postId]
                }
            })
    }
        
    func likePost() {
        liking = true
        likeCancellable = appState.likePost(postId: postId)
            .sink(receiveCompletion: { [weak self] completion in
                print("Liked post")
                self?.liking = false
                if case let .failure(error) = completion {
                    print("Error when liking", error)
                }
            }, receiveValue: {})
    }
    
    func unlikePost() {
        unliking = true
        unlikeCancellable = appState.unlikePost(postId: postId)
            .sink(receiveCompletion: { [weak self] completion in
                self?.unliking = false
                print("Unliked post")
                if case let .failure(error) = completion {
                    print("Error when liking", error)
                }
            }, receiveValue: {})
    }
    
    func deletePost() {
        deleting = true
        deleteCancellable = appState.deletePost(postId: postId)
            .sink(receiveCompletion: { [weak self] completion in
                self?.deleting = false
                if case let .failure(error) = completion {
                    print("Error when deleting", error)
                }
            }, receiveValue: {})
    }
}
