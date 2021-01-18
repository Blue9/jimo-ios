//
//  ProfileViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/14/20.
//

import Foundation
import Combine


class ProfileVM: ObservableObject {
    let appState: AppState
    
    var loadUserCancellable: Cancellable? = nil
    var loadPostsCancellable: Cancellable? = nil
    
    @Published var user: User
    @Published var posts: [PostId]? = nil
    @Published var refreshing = false {
        didSet {
            if oldValue == false && refreshing == true {
                self.refresh()
            }
        }
    }
    @Published var failedToLoadUser = false
    @Published var failedToLoadPosts = false
    
    func refresh() {
        loadUser()
        loadPosts()
    }
    
    func loadUser() {
        loadUserCancellable = appState.getUser(username: user.username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    self.failedToLoadUser = true
                    print("Error when loading user", error)
                } else {
                    self.failedToLoadUser = false
                }
                self.refreshing = false
            }, receiveValue: { user in
                self.user = user
            })
    }
    
    func loadPosts() {
        loadPostsCancellable = appState.getPosts(username: user.username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    self.failedToLoadPosts = true
                    print("Error when loading posts", error)
                } else {
                    self.failedToLoadPosts = false
                }
            }, receiveValue: { posts in
                self.posts = posts
            })
    }
    
    init(appState: AppState, user: User) {
        self.appState = appState
        self.user = user
    }
    
    func getName(user: User) -> String {
        return user.firstName + " " + user.lastName
    }
}
