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
    var loadFollowStatusCancellable: Cancellable? = nil
    var loadPostsCancellable: Cancellable? = nil
    
    var followUserCancellable: Cancellable? = nil
    var unfollowUserCancellable: Cancellable? = nil
    
    @Published var user: User
    @Published var following: Bool = false
    @Published var posts: [PostId]? = nil
    @Published var refreshing = false {
        didSet {
            if oldValue == false && refreshing == true {
                self.refresh()
            }
        }
    }
    @Published var failedToLoadUser = false
    @Published var failedToLoadFollowStatus = false
    @Published var failedToLoadPosts = false
    
    func refresh() {
        loadUser()
        loadFollowStatus()
        loadPosts()
    }
    
    func loadUser() {
        loadUserCancellable = appState.getUser(username: user.username)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.failedToLoadUser = true
                    print("Error when loading user", error)
                } else {
                    self?.failedToLoadUser = false
                }
                self?.refreshing = false
            }, receiveValue: { [weak self] user in
                self?.user = user
            })
    }
    
    func loadFollowStatus() {
        loadFollowStatusCancellable = appState.isFollowing(username: user.username)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.failedToLoadFollowStatus = true
                    print("Error when loading follow status", error)
                } else {
                    self?.failedToLoadFollowStatus = false
                }
            }, receiveValue: { [weak self] response in
                self?.following = response.followed
            })
    }
    
    func loadPosts() {
        loadPostsCancellable = appState.getPosts(username: user.username)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.failedToLoadPosts = true
                    print("Error when loading posts", error)
                } else {
                    self?.failedToLoadPosts = false
                }
            }, receiveValue: { [weak self] posts in
                self?.posts = posts
            })
    }
    
    func followUser() {
        followUserCancellable = appState.followUser(username: user.username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when following", error)
                }
            }, receiveValue: { [weak self] response in
                self?.following = response.followed
                if let count = response.followers {
                    self?.user.followerCount = count
                }

            })
    }
    
    func unfollowUser() {
        unfollowUserCancellable = appState.unfollowUser(username: user.username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when unfollowing", error)
                }
            }, receiveValue: { [weak self] response in
                self?.following = response.followed
                if let count = response.followers {
                    self?.user.followerCount = count
                }
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
