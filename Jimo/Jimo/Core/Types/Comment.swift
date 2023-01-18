//
//  Comment.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/8/21.
//

import Foundation

typealias CommentId = String

struct Comment: Codable, Hashable, Equatable, Identifiable {
    var id: CommentId {
        commentId
    }
    var commentId: CommentId
    var user: PublicUser
    var postId: PostId
    var content: String
    var createdAt: Date
    var likeCount: Int
    var liked: Bool
}

struct CommentPage: Codable {
    var comments: [Comment]
    var cursor: String?
}

struct CreateCommentRequest: Codable {
    var postId: PostId
    var content: String
}

struct LikeCommentResponse: Codable {
    var likes: Int
}
