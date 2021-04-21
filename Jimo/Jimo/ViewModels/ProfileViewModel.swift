//
//  ProfileViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/14/20.
//

import SwiftUI
import Combine

enum ProfileLoadStatus {
    case notInitialized, failed, success
}

class ProfileVM: ObservableObject {
    let appState: AppState
    let globalViewState: GlobalViewState
    
    var loadUserCancellable: Cancellable? = nil
    var loadFollowStatusCancellable: Cancellable? = nil
    var loadPostsCancellable: Cancellable? = nil
    
    var followUserCancellable: Cancellable? = nil
    var unfollowUserCancellable: Cancellable? = nil
    
    @Published var user: User
    @Published var following: Bool = false
    @Published var posts: [PostId] = []
    
    /// This really just tracks the post loading (ignores user and follow status) for simplicity
    @Published var loadStatus = ProfileLoadStatus.notInitialized
    
    var isCurrentUser: Bool {
        guard case let .user(currentUser) = appState.currentUser else {
            return false
        }
        return user.username == currentUser.username
    }
    
    init(appState: AppState, globalViewState: GlobalViewState, user: User) {
        self.appState = appState
        self.globalViewState = globalViewState
        self.user = user
    }
    
    func removePost(postId: PostId) {
        posts = posts.filter({ postId != $0 })
    }
    
    /// Remove any posts that are no longer in the app state (i.e., deleted posts)
    func removeDeletedPosts() {
        withAnimation {
            posts = posts.compactMap({ appState.allPosts.posts[$0]?.postId })
        }
    }
    
    func refresh(onFinish: OnFinish? = nil) {
        loadUser(onFinish: onFinish)
        loadFollowStatus()
        loadPosts()
    }
    
    func loadUser(onFinish: OnFinish? = nil) {
        loadUserCancellable = appState.getUser(username: user.username)
            .sink(receiveCompletion: { [weak self] completion in
                onFinish?()
                if case let .failure(error) = completion {
                    print("Error when loading user", error)
                    if error == .notFound {
                        self?.globalViewState.setError("User not found")
                    } else {
                        self?.globalViewState.setError("Failed to load user")
                    }
                }
            }, receiveValue: { [weak self] user in
                self?.user = user
            })
    }
    
    func loadFollowStatus() {
        guard !isCurrentUser else { return }
        loadFollowStatusCancellable = appState.isFollowing(username: user.username)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Error when loading follow status", error)
                    self?.globalViewState.setError("Failed to load follow status")
                }
            }, receiveValue: { [weak self] response in
                self?.following = response.followed
            })
    }
    
    func loadPosts() {
        loadPostsCancellable = appState.getPosts(username: user.username)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.loadStatus = .failed
                    print("Error when loading posts", error)
                    if error == .notFound {
                        self?.globalViewState.setError("User not found")
                    } else {
                        self?.globalViewState.setError("Failed to load posts")
                    }
                } else {
                    self?.loadStatus = .success
                }
            }, receiveValue: { [weak self] posts in
                if self?.loadStatus == .notInitialized {
                    /// Having the initial load be animated can be kind of jarring
                    self?.posts = posts
                } else {
                    withAnimation {
                        self?.posts = posts
                    }
                }
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
}
