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
        nc.addObserver(self, selector: #selector(postDeleted), name: PostPublisher.postDeleted, object: nil)
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
