//
//  DiscoverViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/8/21.
//

import Foundation
import Combine
import CoreLocation

class DiscoverViewModel: ObservableObject {
    let locationManager = CLLocationManager()
    let nc = NotificationCenter.default

    @Published var posts: [Post] = []
    @Published var initialized = false

    private var loadFeedCancellable: Cancellable?

    var maybeLocation: Location? {
        if let location = locationManager.location {
            return Location(coord: location.coordinate)
        } else {
            return nil
        }
    }

    init() {
        nc.addObserver(self, selector: #selector(postLiked), name: PostPublisher.postLiked, object: nil)
        nc.addObserver(self, selector: #selector(placeSaved), name: PlacePublisher.placeSaved, object: nil)
        nc.addObserver(self, selector: #selector(postUpdated), name: PostPublisher.postUpdated, object: nil)
        nc.addObserver(self, selector: #selector(postDeleted), name: PostPublisher.postDeleted, object: nil)
    }

    @objc private func placeSaved(notification: Notification) {
        let payload = notification.object as! PlaceSavePayload
        let postIndex = posts.indices.first(where: { posts[$0].place.placeId == payload.placeId })
        if let i = postIndex {
            posts[i].saved = payload.save != nil
        }
    }

    @objc private func postLiked(notification: Notification) {
        let like = notification.object as! PostLikePayload
        let postIndex = posts.indices.first(where: { posts[$0].postId == like.postId })
        if let i = postIndex {
            posts[i].likeCount = like.likeCount
            posts[i].liked = like.liked
        }
    }

    @objc private func postUpdated(notification: Notification) {
        let post = notification.object as! Post
        if let i = posts.indices.first(where: { posts[$0].postId == post.postId }) {
            posts[i] = post
        }
    }

    @objc private func postDeleted(notification: Notification) {
        let postId = notification.object as! PostId
        posts.removeAll(where: { $0.postId == postId })
    }

    func loadDiscoverPage(appState: AppState, onFinish: OnFinish? = nil) {
        loadFeedCancellable = appState.discoverFeedV2(location: maybeLocation)
            .sink(receiveCompletion: { [weak self] completion in
                self?.initialized = true
                onFinish?()
                if case let .failure(error) = completion {
                    print("Error when loading posts", error)
                }
            }, receiveValue: { [weak self] feed in
                self?.posts = feed.posts
            })
    }
}
