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
    let globalViewState: GlobalViewState
    let postId: PostId
    
    @Published var liking = false
    @Published var unliking = false
    @Published var deleting = false
    @Published var post: Post?
    
    var updatePostCancellable: Cancellable? = nil
    var likeCancellable: Cancellable? = nil
    var unlikeCancellable: Cancellable? = nil
    var deleteCancellable: Cancellable? = nil
    var reportCancellable: Cancellable? = nil
    
    var onDelete: (() -> Void)?
    
    init(appState: AppState, viewState: GlobalViewState, postId: PostId, onDelete: (() -> Void)? = nil) {
        self.appState = appState
        self.globalViewState = viewState
        self.postId = postId
        self.post = appState.allPosts.posts[postId]
        self.onDelete = onDelete
    }
    
    deinit {
        stopListeningToPostUpdates()
    }
    
    func listenToPostUpdates() {
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
    
    func stopListeningToPostUpdates() {
        updatePostCancellable?.cancel()
    }
        
    func likePost() {
        liking = true
        likeCancellable = appState.likePost(postId: postId)
            .sink(receiveCompletion: { [weak self] completion in
                print("Liked post")
                self?.liking = false
                if case let .failure(error) = completion {
                    print("Error when liking", error)
                    self?.globalViewState.setError("Failed to like post")
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
                    print("Error when unliking", error)
                    self?.globalViewState.setError("Failed to unlike post")
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
                    self?.globalViewState.setError("Failed to delete post")
                }
            }, receiveValue: { [weak self] _ in
                if let onDelete = self?.onDelete {
                    onDelete()
                }
            })
    }
    
    func reportPost(details: String) {
        reportCancellable = appState.reportPost(postId: postId, details: details)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Error when reporting", error)
                    self?.globalViewState.setError("Failed to report post")
                }
            }, receiveValue: { [weak self] response in
                if response.success {
                    self?.globalViewState.setSuccess("Reported post! Thank you for keeping jimo a safe community.")
                } else {
                    self?.globalViewState.setWarning("Already reported this post.")
                }
            })
    }
}
