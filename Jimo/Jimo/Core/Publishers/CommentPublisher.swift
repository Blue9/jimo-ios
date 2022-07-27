//
//  CommentPublisher.swift
//  Jimo
//
//  Created by Gautam Mekkat on 7/25/21.
//

import Foundation

struct CommentLikePayload {
    var commentId: CommentId
    var likeCount: Int
    var liked: Bool
}

class CommentPublisher {
    let notificationCenter = NotificationCenter.default
    
    static let commentCreated = Notification.Name("comment:created")
    static let commentLikes = Notification.Name("comment:likes")
    static let commentDeleted = Notification.Name("comment:deleted")
    
    func commentCreated(comment: Comment) {
        notificationCenter.post(name: CommentPublisher.commentCreated, object: comment)
    }
    
    func commentLikes(commentId: CommentId, likeCount: Int, liked: Bool) {
        notificationCenter.post(name: CommentPublisher.commentLikes, object: CommentLikePayload(commentId: commentId, likeCount: likeCount, liked: liked))
    }
    
    func commentDeleted(commentId: CommentId) {
        notificationCenter.post(name: CommentPublisher.commentDeleted, object: commentId)
    }
}
