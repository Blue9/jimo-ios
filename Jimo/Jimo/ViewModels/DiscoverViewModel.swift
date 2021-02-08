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
    @Published var refreshing: Bool = false {
        didSet {
            if refreshing {
                self.loadDiscoverPage()
            }
        }
    }
    
    var appState: AppState?
    private var cancellable: Cancellable? = nil
    private var allPostsCancellable: Cancellable? = nil
    
    func loadDiscoverPage(initialLoad: Bool = false) {
        guard let appState = appState else {
            if initialLoad {
                self.initialized = true
            }
            return
        }
        cancellable = appState.discoverFeed()
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Error when loading posts", error)
                }
                if initialLoad {
                    self?.initialized = true
                }
            }, receiveValue: { [weak self] posts in
                self?.posts = posts
                self?.refreshing = false
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
}
