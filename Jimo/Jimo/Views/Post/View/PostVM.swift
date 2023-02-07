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

    @Published var post: Post
    @Published var liking = false
    @Published var unliking = false
    @Published var deleting = false

    var cancelBag: Set<AnyCancellable> = .init()

    init(post: Post) {
        self.post = post
        nc.addObserver(self, selector: #selector(postLiked), name: PostPublisher.postLiked, object: nil)
        nc.addObserver(self, selector: #selector(placeSaved), name: PlacePublisher.placeSaved, object: nil)
        nc.addObserver(self, selector: #selector(postUpdated), name: PostPublisher.postUpdated, object: nil)
    }

    @objc func postLiked(notification: Notification) {
        let like = notification.object as! PostLikePayload
        if post.id == like.postId {
            self.post.liked = like.liked
            self.post.likeCount = like.likeCount
        }
    }

    @objc func placeSaved(notification: Notification) {
        let payload = notification.object as! PlaceSavePayload
        if post.place.id == payload.placeId {
            self.post.saved = payload.save != nil
        }
    }

    @objc func postUpdated(notification: Notification) {
        let updated = notification.object as! Post
        if updated.postId == post.postId {
            self.post = updated
        }
    }

    func likePost(postId: PostId, appState: AppState, viewState: GlobalViewState) {
        liking = true
        appState.likePost(postId: postId)
            .sink(receiveCompletion: { [weak self] completion in
                self?.liking = false
                if case let .failure(error) = completion {
                    print("Error when liking", error)
                    viewState.setError("Failed to like post")
                }
            }, receiveValue: { _ in
                print("Liked post")
            }).store(in: &cancelBag)
    }

    func unlikePost(postId: PostId, appState: AppState, viewState: GlobalViewState) {
        unliking = true
        appState.unlikePost(postId: postId)
            .sink(receiveCompletion: { [weak self] completion in
                self?.unliking = false
                if case let .failure(error) = completion {
                    print("Error when unliking", error)
                    viewState.setError("Failed to unlike post")
                }
            }, receiveValue: { _ in
                print("Unliked post")
            }).store(in: &cancelBag)
    }

    func savePlace(placeId: PlaceId, appState: AppState, viewState: GlobalViewState) {
        appState.savePlace(placeId: placeId, note: "Want to go")
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when saving place", error)
                    viewState.setError("Could not save place")
                }
            }, receiveValue: { _ in })
            .store(in: &cancelBag)
    }

    func unsavePlace(placeId: PlaceId, appState: AppState, viewState: GlobalViewState) {
        appState.unsavePlace(placeId)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when unsaving post", error)
                    viewState.setError("Could not unsave post")
                }
            }, receiveValue: { _ in })
            .store(in: &cancelBag)
    }

    func deletePost(postId: PostId, appState: AppState, viewState: GlobalViewState) {
        deleting = true
        appState.deletePost(postId: postId)
            .sink(receiveCompletion: { [weak self] completion in
                self?.deleting = false
                if case let .failure(error) = completion {
                    print("Error when deleting", error)
                    viewState.setError("Failed to delete post")
                }
            }, receiveValue: {}).store(in: &cancelBag)
    }

    func reportPost(postId: PostId, details: String, appState: AppState, viewState: GlobalViewState) {
        appState.reportPost(postId: postId, details: details)
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
            }).store(in: &cancelBag)
    }
}
