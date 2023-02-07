//
//  CommentsViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/8/21.
//

import Foundation
import Combine

class ViewPostCommentsViewModel: ObservableObject {
    let nc = NotificationCenter.default

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

    init() {
        nc.addObserver(self, selector: #selector(commentCreated), name: CommentPublisher.commentCreated, object: nil)
        nc.addObserver(self, selector: #selector(commentLikes), name: CommentPublisher.commentLikes, object: nil)
        nc.addObserver(self, selector: #selector(commentDeleted), name: CommentPublisher.commentDeleted, object: nil)
    }

    @objc private func commentCreated(notification: Notification) {
        let comment = notification.object as! Comment
        if comment.postId == postId {
            self.comments.insert(comment, at: 0)
        }
    }

    @objc private func commentLikes(notification: Notification) {
        let like = notification.object as! CommentLikePayload
        let commentIndex = comments.indices.first(where: { comments[$0].commentId == like.commentId })
        if let i = commentIndex {
            comments[i].likeCount = like.likeCount
            comments[i].liked = like.liked
        }
    }

    @objc private func commentDeleted(notification: Notification) {
        let commentId = notification.object as! CommentId
        comments.removeAll(where: { $0.commentId == commentId })
    }

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
            } receiveValue: { [weak self] _ in
                self?.newCommentText = ""
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
        deleteCommentCancellable = appState.deleteComment(for: postId, commentId: commentId)
            .sink { completion in
                if case .failure = completion {
                    viewState.setError("Could not delete comment")
                }
            } receiveValue: { response in
                if !response.success {
                    viewState.setError("Could not delete comment")
                } else {
                    viewState.setSuccess("Deleted comment")
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
