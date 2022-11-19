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
    let nc = NotificationCenter.default
    
    var loadUserCancellable: Cancellable? = nil
    var loadRelationCancellable: Cancellable? = nil
    var loadPostsCancellable: Cancellable? = nil
    
    var relationCancellable: AnyCancellable?
    
    @Published var user: PublicUser?
    @Published var loadedRelation = false
    @Published var relationToUser: UserRelation?
    @Published var posts: [Post] = []
    @Published var cursor: String?
    
    /// This really just tracks the post loading (ignores user and follow status) for simplicity
    @Published var loadStatus = ProfileLoadStatus.notInitialized
    @Published var loadingMore = false
    
    @Published var showSearchUsers = false
    
    init() {
        nc.addObserver(self, selector: #selector(postCreated), name: PostPublisher.postCreated, object: nil)
        nc.addObserver(self, selector: #selector(postUpdated), name: PostPublisher.postUpdated, object: nil)
        nc.addObserver(self, selector: #selector(postLiked), name: PostPublisher.postLiked, object: nil)
        nc.addObserver(self, selector: #selector(postSaved), name: PostPublisher.postSaved, object: nil)
        nc.addObserver(self, selector: #selector(postDeleted), name: PostPublisher.postDeleted, object: nil)
    }
    
    @objc private func postCreated(notification: Notification) {
        let post = notification.object as! Post
        if post.user.id == user?.id {
            posts.insert(post, at: 0)
        }
    }
    
    @objc private func postUpdated(notification: Notification) {
        let post = notification.object as! Post
        if let i = posts.indices.first(where: { posts[$0].postId == post.postId }) {
            posts[i] = post
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
    
    @objc private func postSaved(notification: Notification) {
        let save = notification.object as! PostSavePayload
        let postIndex = posts.indices.first(where: { posts[$0].postId == save.postId })
        if let i = postIndex {
            posts[i].saved = save.saved
        }
    }
    
    @objc private func postDeleted(notification: Notification) {
        let postId = notification.object as! PostId
        posts.removeAll(where: { $0.postId == postId })
    }
    
    func isCurrentUser(appState: AppState, username: String) -> Bool {
        guard case let .user(currentUser) = appState.currentUser else {
            return false
        }
        return username == currentUser.username
    }
    
    func removePost(postId: PostId) {
        posts = posts.filter({ postId != $0.postId })
    }
    
    func refresh(username: String, appState: AppState, viewState: GlobalViewState, onFinish: OnFinish? = nil) {
        loadUser(username: username, appState: appState, viewState: viewState)
        loadRelation(username: username, appState: appState, viewState: viewState)
        loadPosts(username: username, appState: appState, viewState: viewState, onFinish: onFinish)
    }
    
    func loadUser(username: String, appState: AppState, viewState: GlobalViewState) {
        loadUserCancellable = appState.getUser(username: username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when loading user", error)
                    if error == .notFound {
                        viewState.setError("User not found")
                    } else {
                        viewState.setError("Failed to load user")
                    }
                }
            }, receiveValue: { [weak self] user in
                self?.user = user
            })
    }
    
    func loadRelation(username: String, appState: AppState, viewState: GlobalViewState) {
        guard !isCurrentUser(appState: appState, username: username) else { return }
        loadRelationCancellable = appState.relation(to: username)
            .sink { completion in
                if case let .failure(error) = completion {
                    print("Error when loading follow status (v2)", error)
                    viewState.setError("Failed to load follow status")
                }
            } receiveValue: { [weak self] relation in
                self?.relationToUser = relation.relation
                self?.loadedRelation = true
            }
    }
    
    func loadPosts(username: String, appState: AppState, viewState: GlobalViewState, onFinish: OnFinish? = nil) {
        loadPostsCancellable = appState.getPosts(username: username)
            .sink(receiveCompletion: { [weak self] completion in
                onFinish?()
                if case let .failure(error) = completion {
                    self?.loadStatus = .failed
                    print("Error when loading posts", error)
                    if error == .notFound {
                        viewState.setError("User not found")
                    } else {
                        viewState.setError("Failed to load posts")
                    }
                } else {
                    self?.loadStatus = .success
                }
            }, receiveValue: { [weak self] userFeed in
                self?.posts = userFeed.posts
                self?.cursor = userFeed.cursor
            })
    }
    
    func loadMorePosts(username: String, appState: AppState, viewState: GlobalViewState) {
        guard let cursor = cursor else {
            // No more to load
            return
        }
        loadingMore = true
        loadPostsCancellable = appState.getPosts(username: username, cursor: cursor)
            .sink(receiveCompletion: { [weak self] completion in
                self?.loadingMore = false
                if case let .failure(error) = completion {
                    print("Error when loading more posts", error)
                    viewState.setError("Failed to load more posts")
                }
            }, receiveValue: { [weak self] userFeed in
                self?.posts.append(contentsOf: userFeed.posts)
                self?.cursor = userFeed.cursor
            })
    }
    
    func followUser(username: String, appState: AppState, viewState: GlobalViewState) {
        relationCancellable = appState.followUser(username: username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when following", error)
                }
            }, receiveValue: { [weak self] response in
                self?.relationToUser = response.followed ? .following : nil
                if let count = response.followers {
                    self?.user?.followerCount = count
                }
            })
    }
    
    func unfollowUser(username: String, appState: AppState, viewState: GlobalViewState) {
        relationCancellable = appState.unfollowUser(username: username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when unfollowing", error)
                }
            }, receiveValue: { [weak self] response in
                self?.relationToUser = response.followed ? .following : nil
                if let count = response.followers {
                    self?.user?.followerCount = count
                }
            })
    }
    
    func blockUser(username: String, appState: AppState, viewState: GlobalViewState) {
        guard relationToUser == nil else {
            viewState.setError("Cannot block someone you already follow or block")
            return
        }
        relationCancellable = appState.blockUser(username: username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    if case let .requestError(maybeErrors) = error,
                       let errors = maybeErrors,
                       let first = errors.first {
                        viewState.setError(first.value)
                    } else {
                        viewState.setError("Could not block user")
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
    
    func unblockUser(username: String, appState: AppState, viewState: GlobalViewState) {
        guard relationToUser == .blocked else {
            viewState.setError("This user is not blocked")
            return
        }
        relationCancellable = appState.unblockUser(username: username)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    if case let .requestError(maybeErrors) = error,
                       let errors = maybeErrors,
                       let first = errors.first {
                        viewState.setError(first.value)
                    } else {
                        viewState.setError("Could not unblock user")
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

extension DeepLinkProfileLoadingScreen {
    class ViewModel: ObservableObject {
        @Published var initialUser: User?
        @Published var loadStatus: ProfileLoadStatus = .notInitialized
        
        var loadUserCancellable: Cancellable?
        
        func loadProfile(with appState: AppState, viewState: GlobalViewState, username: String) {
            loadUserCancellable = appState.getUser(username: username)
                .sink { [weak self] in
                    if case let .failure(error) = $0 {
                        print("Error when loading user", error)
                        viewState.setError("User not found")
                        self?.loadStatus = .failed
                    }
                } receiveValue: { [weak self] in
                    self?.initialUser = $0
                    self?.loadStatus = .success
                }
        }
    }
}
