//
//  PostVM.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/10/21.
//

import SwiftUI
import Combine

class PostVM: ObservableObject {
    let nc = NotificationCenter.default
    
    @Published var post: Post?
    @Published var liking = false
    @Published var unliking = false
    @Published var deleting = false
    
    var updatePostCancellable: Cancellable? = nil
    var likeCancellable: Cancellable? = nil
    var unlikeCancellable: Cancellable? = nil
    var deleteCancellable: Cancellable? = nil
    var reportCancellable: Cancellable? = nil
    
    var onDelete: (() -> ())?
    
    /// Listen for post updates and update the current post (optional to call this, only necessary if you want to listen to updates)
    func listen(post: Post, onDelete: @escaping () -> ()) {
        guard self.post == nil else {
            return
        }
        self.post = post
        self.onDelete = onDelete
        nc.addObserver(self, selector: #selector(postLiked), name: PostPublisher.postLiked, object: nil)
        nc.addObserver(self, selector: #selector(postUpdated), name: PostPublisher.postUpdated, object: nil)
        nc.addObserver(self, selector: #selector(postDeleted), name: PostPublisher.postDeleted, object: nil)
    }
    
    @objc func postLiked(notification: Notification) {
        guard let postId = post?.id else {
            return
        }
        let like = notification.object as! PostLikePayload
        if postId == like.postId {
            self.post?.liked = like.liked
            self.post?.likeCount = like.likeCount
        }
    }
    
    @objc func postUpdated(notification: Notification) {
        self.post = notification.object as? Post
    }
    
    @objc func postDeleted(notification: Notification) {
        guard let post = post, let onDelete = onDelete else {
            return
        }
        let deletedPostId = notification.object as! PostId
        if post.id == deletedPostId {
            onDelete()
        }
    }
    
    func likePost(postId: PostId, appState: AppState, viewState: GlobalViewState) {
        liking = true
        likeCancellable = appState.likePost(postId: postId)
            .sink(receiveCompletion: { [weak self] completion in
                self?.liking = false
                if case let .failure(error) = completion {
                    print("Error when liking", error)
                    viewState.setError("Failed to like post")
                }
            }, receiveValue: { response in
                print("Liked post")
            })
    }
    
    func unlikePost(postId: PostId, appState: AppState, viewState: GlobalViewState) {
        unliking = true
        unlikeCancellable = appState.unlikePost(postId: postId)
            .sink(receiveCompletion: { [weak self] completion in
                self?.unliking = false
                if case let .failure(error) = completion {
                    print("Error when unliking", error)
                    viewState.setError("Failed to unlike post")
                }
            }, receiveValue: { response in
                print("Unliked post")
            })
    }
    
    func deletePost(postId: PostId, appState: AppState, viewState: GlobalViewState) {
        deleting = true
        deleteCancellable = appState.deletePost(postId: postId)
            .sink(receiveCompletion: { [weak self] completion in
                self?.deleting = false
                if case let .failure(error) = completion {
                    print("Error when deleting", error)
                    viewState.setError("Failed to delete post")
                }
            }, receiveValue: {})
    }
    
    func reportPost(postId: PostId, details: String, appState: AppState, viewState: GlobalViewState) {
        reportCancellable = appState.reportPost(postId: postId, details: details)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when reporting", error)
                    viewState.setError("Failed to report post")
                }
            }, receiveValue: { response in
                if response.success {
                    viewState.setSuccess("Reported post! Thank you for keeping Jimo a safe community.")
                } else {
                    viewState.setWarning("You already reported this post.")
                }
            })
    }
}
