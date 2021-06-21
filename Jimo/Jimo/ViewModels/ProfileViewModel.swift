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
    var loadRelationCancellable: Cancellable? = nil
    var loadPostsCancellable: Cancellable? = nil
    
    var relationCancellable: AnyCancellable?
    
    @Published var user: User
    @Published var loadedRelation = false
    @Published var relationToUser: UserRelation?
    @Published var posts: [PostId] = []
    @Published var cursor: String?
    
    /// This really just tracks the post loading (ignores user and follow status) for simplicity
    @Published var loadStatus = ProfileLoadStatus.notInitialized
    @Published var loadingMore = false
    
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
        posts = posts.compactMap({ appState.allPosts.posts[$0]?.postId })
    }
    
    func refresh(onFinish: OnFinish? = nil) {
        loadUser()
        loadRelation()
        loadPosts(onFinish: onFinish)
    }
    
    func loadUser() {
        loadUserCancellable = appState.getUser(username: user.username)
            .sink(receiveCompletion: { [weak self] completion in
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
    
    func loadRelation() {
        guard !isCurrentUser else { return }
        loadRelationCancellable = appState.relation(to: user.username)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Error when loading follow status (v2)", error)
                    self?.globalViewState.setError("Failed to load follow status")
                }
            } receiveValue: { [weak self] relation in
                self?.relationToUser = relation.relation
                self?.loadedRelation = true
            }
    }
    
    func loadPosts(onFinish: OnFinish? = nil) {
        loadPostsCancellable = appState.getPosts(username: user.username)
            .sink(receiveCompletion: { [weak self] completion in
                onFinish?()
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
            }, receiveValue: { [weak self] userFeed in
                self?.posts = userFeed.posts.map { $0.postId }
                self?.cursor = userFeed.cursor
            })
    }
    
    func loadMorePosts() {
        guard let cursor = cursor else {
            // No more to load
            return
        }
        loadingMore = true
        loadPostsCancellable = appState.getPosts(username: user.username, cursor: cursor)
            .sink(receiveCompletion: { [weak self] completion in
                self?.loadingMore = false
                if case let .failure(error) = completion {
                    print("Error when loading more posts", error)
                    self?.globalViewState.setError("Failed to load more posts")
                }
            }, receiveValue: { [weak self] userFeed in
                self?.posts.append(contentsOf: userFeed.posts.map { $0.postId })
                self?.cursor = userFeed.cursor
            })
    }
    
    func followUser() {
        relationCancellable = appState.followUser(username: user.username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when following", error)
                }
            }, receiveValue: { [weak self] response in
                self?.relationToUser = response.followed ? .following : nil
                if let count = response.followers {
                    self?.user.followerCount = count
                }
            })
    }
    
    func unfollowUser() {
        relationCancellable = appState.unfollowUser(username: user.username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when unfollowing", error)
                }
            }, receiveValue: { [weak self] response in
                self?.relationToUser = response.followed ? .following : nil
                if let count = response.followers {
                    self?.user.followerCount = count
                }
            })
    }
    
    func blockUser() {
        guard relationToUser == nil else {
            globalViewState.setError("Cannot block someone you already follow or block")
            return
        }
        relationCancellable = appState.blockUser(username: user.username)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    if case let .requestError(maybeErrors) = error,
                       let errors = maybeErrors,
                       let first = errors.first {
                        self?.globalViewState.setError(first.value)
                    } else {
                        self?.globalViewState.setError("Could not block user")
                    }
                    print("Error when blocking user", error)
                }
            }, receiveValue: { [weak self] response in
                if response.success {
                    self?.relationToUser = .blocked
                    self?.posts.removeAll()
                }
            })
    }
    
    func unblockUser() {
        guard relationToUser == .blocked else {
            globalViewState.setError("This user is not blocked")
            return
        }
        relationCancellable = appState.unblockUser(username: user.username)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    if case let .requestError(maybeErrors) = error,
                       let errors = maybeErrors,
                       let first = errors.first {
                        self?.globalViewState.setError(first.value)
                    } else {
                        self?.globalViewState.setError("Could not unblock user")
                    }
                    print("Error when unblocking user", error)
                }
            }, receiveValue: { [weak self] response in
                if response.success {
                    self?.relationToUser = nil
                }
            })
    }
}
