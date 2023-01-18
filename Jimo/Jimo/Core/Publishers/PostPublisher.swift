//
//  PostPublisher.swift
//  Jimo
//
//  Created by Gautam Mekkat on 7/19/21.
//

import Foundation

struct PostLikePayload {
    var postId: PostId
    var likeCount: Int
    var liked: Bool
}

struct PostSavePayload {
    var postId: PostId
    var saved: Bool
}

class PostPublisher {
    let notificationCenter = NotificationCenter.default

    static let postCreated = Notification.Name("post:created")
    static let postUpdated = Notification.Name("post:updated")
    static let postLiked = Notification.Name("post:liked")
    static let postSaved = Notification.Name("post:saved")
    static let postDeleted = Notification.Name("post:deleted")

    func postCreated(post: Post) {
        notificationCenter.post(name: PostPublisher.postCreated, object: post)
    }

    func postUpdated(post: Post) {
        notificationCenter.post(name: PostPublisher.postUpdated, object: post)
    }

    func postLiked(postId: PostId, likeCount: Int) {
        notificationCenter.post(name: PostPublisher.postLiked, object: PostLikePayload(postId: postId, likeCount: likeCount, liked: true))
    }

    func postUnliked(postId: PostId, likeCount: Int) {
        notificationCenter.post(name: PostPublisher.postLiked, object: PostLikePayload(postId: postId, likeCount: likeCount, liked: false))
    }

    func postSaved(postId: PostId) {
        notificationCenter.post(name: PostPublisher.postSaved, object: PostSavePayload(postId: postId, saved: true))
    }

    func postUnsaved(postId: PostId) {
        notificationCenter.post(name: PostPublisher.postSaved, object: PostSavePayload(postId: postId, saved: false))
    }

    func postDeleted(postId: PostId) {
        notificationCenter.post(name: PostPublisher.postDeleted, object: postId)
    }
}
