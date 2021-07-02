//
//  CommentsViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/8/21.
//

import Foundation
import Combine

class SingleCommentVM: ObservableObject {
    @Published var likingComment = false
    var cancellable: AnyCancellable?
    
    func likeComment(
        appState: AppState,
        globalViewState: GlobalViewState,
        commentId: CommentId,
        then: @escaping (Int) -> ()
    ) {
        likingComment = true
        cancellable = appState.likeComment(commentId: commentId)
            .sink { [weak self] completion in
                self?.likingComment = false
                if case .failure(_) = completion {
                    globalViewState.setError("Could not like comment")
                }
            } receiveValue: { response in
                then(response.likes)
            }
    }
    
    func unlikeComment(
        appState: AppState,
        globalViewState: GlobalViewState,
        commentId: CommentId,
        then: @escaping (Int) -> ()
    ) {
        likingComment = true
        cancellable = appState.unlikeComment(commentId: commentId)
            .sink { [weak self] completion in
                self?.likingComment = false
                if case .failure(_) = completion {
                    globalViewState.setError("Could not unlike comment")
                }
            } receiveValue: { response in
                then(response.likes)
            }
    }
}

class CommentsViewModel: ObservableObject {
    @Published var newCommentText = ""
    @Published var creatingComment = false
    @Published var comments: [Comment] = []
    @Published var loadingComments = false
    var cursor: String?
    
    var postId: PostId?
    var highlightedComment: Comment? {
        didSet {
            if let comment = highlightedComment {
                comments.removeAll()
                comments.append(comment)
            }
        }
    }
    var appState: AppState?
    var viewState: GlobalViewState?
    
    var refreshCommentsCancellable: AnyCancellable?
    var createCommentCancellable: AnyCancellable?
    var deleteCommentCancellable: AnyCancellable?
    
    func createComment() {
        guard let postId = postId, let appState = appState, let viewState = viewState else {
            return
        }
        guard newCommentText.count > 0 else {
            viewState.setWarning("Comment cannot be empty")
            return
        }
        creatingComment = true
        createCommentCancellable = appState.createComment(for: postId, content: newCommentText)
            .sink { [weak self] completion in
                self?.creatingComment = false
                if case let .failure(error) = completion {
                    print("Error when loading comments", error)
                    viewState.setError(error.message ?? "Could not create comment")
                }
            } receiveValue: { [weak self] comment in
                self?.comments.insert(comment, at: 0)
                self?.newCommentText = ""
                appState.allPosts.posts[postId]?.commentCount += 1
            }
    }
    
    func loadComments(onFinish: OnFinish? = nil) {
        guard let postId = postId, let appState = appState, let viewState = viewState else {
            onFinish?()
            return
        }
        loadingComments = true
        refreshCommentsCancellable = appState.getComments(for: postId)
            .sink { [weak self] completion in
                self?.loadingComments = false
                onFinish?()
                if case let .failure(error) = completion {
                    print("Error when loading comments", error)
                    viewState.setError(error.message ?? "Could not load comments")
                }
            } receiveValue: { [weak self] commentPage in
                self?.comments = commentPage.comments.filter { $0.commentId != self?.highlightedComment?.commentId }
                if let comment = self?.highlightedComment {
                    self?.comments.insert(comment, at: 0)
                }
                self?.cursor = commentPage.cursor
            }
    }
    
    func deleteComment(commentId: CommentId) {
        guard let postId = postId, let appState = appState, let viewState = viewState else {
            return
        }
        deleteCommentCancellable = appState.deleteComment(commentId: commentId)
            .sink { completion in
                if case .failure(_) = completion {
                    viewState.setError("Could not delete comment")
                }
            } receiveValue: { [weak self] response in
                if !response.success {
                    viewState.setError("Could not delete comment")
                } else {
                    viewState.setSuccess("Deleted comment")
                    self?.comments.removeAll { $0.commentId == commentId }
                    appState.allPosts.posts[postId]?.commentCount -= 1
                }
            }
    }
    
    func loadMore() {
        guard let postId = postId, let cursor = cursor, let appState = appState, let viewState = viewState else {
            return
        }
        loadingComments = true
        refreshCommentsCancellable = appState.getComments(for: postId, cursor: cursor)
            .sink { [weak self] completion in
                self?.loadingComments = false
                if case let .failure(error) = completion {
                    print("Error when loading more comments", error)
                    viewState.setError(error.message ?? "Could not load more comments")
                }
            } receiveValue: { [weak self] commentPage in
                let toAdd = commentPage.comments.filter { $0.commentId != self?.highlightedComment?.commentId }
                self?.comments.append(contentsOf: toAdd)
                self?.cursor = commentPage.cursor
            }
    }
}