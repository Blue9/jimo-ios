//
//  FeedItemVM.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/10/21.
//

import SwiftUI
import Combine
import FirebaseAnalytics
<<<<<<< Updated upstream

=======
>>>>>>> Stashed changes

class FeedItemVM: ObservableObject {
    @Published var liking = false
    @Published var unliking = false
    @Published var deleting = false
    
    var updatePostCancellable: Cancellable? = nil
    var likeCancellable: Cancellable? = nil
    var unlikeCancellable: Cancellable? = nil
    var deleteCancellable: Cancellable? = nil
    var reportCancellable: Cancellable? = nil
    
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
<<<<<<< Updated upstream
                print("*******************liked_post************************")
                print("liked_post")
                Analytics.logEvent("liked_post", parameters: nil)
                print("*****************************************************")
=======
                print(">>>liked_post")
                Analytics.logEvent("liked_post", parameters: nil)
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
                print("*******************unliked_post**********************")
                print("unliked_post")
                Analytics.logEvent("unliked_post", parameters: nil)
                print("*****************************************************")
=======
                print(">>>unliked_post")
                Analytics.logEvent("unliked_post", parameters: nil)
>>>>>>> Stashed changes
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
<<<<<<< Updated upstream
            }, receiveValue: { response in
                    print("deleted post")
                    print("*******************deleted_post************************")
                    print("deleted_post")
                    Analytics.logEvent("deleted_post", parameters: nil)
                    print("*******************************************************")
=======
            }, receiveValue: {
                print(">>>deleted_post")
                Analytics.logEvent("deleted_post", parameters: nil)
>>>>>>> Stashed changes
            })
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
                    viewState.setSuccess("Reported post! Thank you for keeping jimo a safe community.")
<<<<<<< Updated upstream
=======
                    print(">>>reported_post")
>>>>>>> Stashed changes
                    Analytics.logEvent("reported_post", parameters: nil)
                } else {
                    viewState.setWarning("You already reported this post.")
                }
            })
    }
}
