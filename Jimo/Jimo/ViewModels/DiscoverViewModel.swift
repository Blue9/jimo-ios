//
//  DiscoverViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/8/21.
//

import Foundation
import Combine

class DiscoverViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var initialized: Bool = false
    
    var appState: AppState?
    private var loadFeedCancellable: Cancellable? = nil
    private var allPostsCancellable: Cancellable? = nil
    
    func loadDiscoverPage(initialLoad: Bool = false, onFinish: OnFinish? = nil) {
        guard let appState = appState else {
            if initialLoad {
                self.initialized = true
            }
            onFinish?()
            return
        }
        loadFeedCancellable = appState.discoverFeed()
            .sink(receiveCompletion: { [weak self] completion in
                onFinish?()
                if case let .failure(error) = completion {
                    print("Error when loading posts", error)
                }
                if initialLoad {
                    self?.initialized = true
                }
            }, receiveValue: { [weak self] posts in
                self?.posts = posts
            })
    }
    
    func listenToPostUpdates() {
        allPostsCancellable = appState?.allPosts.$posts
            .sink(receiveValue: { [weak self] posts in
                guard let self = self else {
                    return
                }
                self.posts = self.posts.compactMap({ post in posts[post.postId] })
            })
    }
    
    func stopListeningToPostUpdates() {
        allPostsCancellable?.cancel()
    }
}
