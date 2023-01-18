//
//  SavedPosts.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/10/22.
//

import SwiftUI
import Combine

private enum LoadStatus {
    case notInitialized, loaded, failed
}

struct SavedPostsFeed: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @StateObject var viewModel = ViewModel()
    @State private var showFullPost: PostId?

    private var columns: [GridItem] = [
        GridItem(.flexible(minimum: 50), spacing: 2),
        GridItem(.flexible(minimum: 50), spacing: 2),
        GridItem(.flexible(minimum: 50), spacing: 2)
    ]

    @ViewBuilder
    private func postView(for postId: PostId?) -> some View {
        if let post = viewModel.posts.first(where: { $0.id == postId }) {
            ViewPost(initialPost: post)
        } else {
            EmptyView().onAppear { showFullPost = nil }
        }
    }

    var initializedView: some View {
        RefreshableScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.posts) { post in
                    NavigationLink(destination: ViewPost(initialPost: post)) {
                        PostGridCell(post: post)
                    }
                }
            }
        } onRefresh: { onFinish in
            viewModel.refresh(appState: appState, globalViewState: viewState, onFinish: onFinish)
        } onLoadMore: {
            viewModel.loadMore(appState: appState, globalViewState: viewState)
        }
    }

    var body: some View {
        Group {
            switch viewModel.status {
            case .notInitialized:
                ProgressView()
                    .onAppear {
                        viewModel.refresh(appState: appState, globalViewState: viewState)
                    }
            case .failed:
                Button("Try again") {
                    viewModel.refresh(appState: appState, globalViewState: viewState)
                }
                .padding(20)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            case .loaded:
                initializedView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(Color("background")))
        .navigationTitle(Text("Saved Posts"))
        .trackScreen(.savedPosts)
    }
}

extension SavedPostsFeed {
    class ViewModel: ObservableObject {
        let nc = NotificationCenter.default

        @Published fileprivate var status: LoadStatus = .notInitialized
        @Published var posts: [Post] = []
        @Published var loadingMore = false
        var cursor: PostId?

        var cancelBag: Set<AnyCancellable> = .init()

        init() {
            nc.addObserver(self, selector: #selector(postCreated), name: PostPublisher.postCreated, object: nil)
            nc.addObserver(self, selector: #selector(postUpdated), name: PostPublisher.postUpdated, object: nil)
            nc.addObserver(self, selector: #selector(postLiked), name: PostPublisher.postLiked, object: nil)
            nc.addObserver(self, selector: #selector(postSaved), name: PostPublisher.postSaved, object: nil)
            nc.addObserver(self, selector: #selector(postDeleted), name: PostPublisher.postDeleted, object: nil)
        }

        @objc private func postCreated(notification: Notification) {
            let post = notification.object as! Post
            posts.insert(post, at: 0)
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

        func refresh(appState: AppState, globalViewState: GlobalViewState, onFinish: OnFinish? = nil) {
            self.cursor = nil
            appState.getSavedPosts().sink { [weak self] completion in
                if case .failure = completion {
                    globalViewState.setError("Could not load saved posts")
                    self?.status = .failed
                    onFinish?()
                }
            } receiveValue: { [weak self] response in
                self?.cursor = response.cursor
                self?.posts = response.posts
                self?.status = .loaded
                onFinish?()
            }.store(in: &cancelBag)
        }

        func loadMore(appState: AppState, globalViewState: GlobalViewState) {
            guard cursor != nil else {
                return
            }
            loadingMore = true
            appState.getSavedPosts(cursor: cursor).sink { [weak self] completion in
                self?.loadingMore = false
                if case .failure = completion {
                    globalViewState.setError("Could not load more saved posts")
                }
            } receiveValue: { [weak self] response in
                self?.cursor = response.cursor
                self?.posts.append(contentsOf: response.posts)
            }.store(in: &cancelBag)
        }
    }
}
