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
    
    var likeCancellable: Cancellable? = nil
    var unlikeCancellable: Cancellable? = nil

    init(appState: AppState, postId: PostId) {
        self.appState = appState
        self.postId = postId
    }
        
    func likePost() {
        liking = true
        likeCancellable = appState.likePost(postId: postId)
            .sink(receiveCompletion: { completion in
                self.liking = false
                if case let .failure(error) = completion {
                    print("Error when liking", error)
                }
            }, receiveValue: {})
    }
    
    func unlikePost() {
        unliking = true
        unlikeCancellable = appState.unlikePost(postId: postId)
            .sink(receiveCompletion: { completion in
                self.unliking = false
                if case let .failure(error) = completion {
                    print("Error when liking", error)
                }
            }, receiveValue: {})
    }
}
