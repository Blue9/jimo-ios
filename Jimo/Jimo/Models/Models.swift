//
//  Models.swift
//  Jimo
//
//  Created by Gautam Mekkat on 7/19/21.
//

import Foundation

struct Page<T> {
    let items: [T]
    let cursor: String?
}

class PostModel: ObservableObject {
    let postId: PostId
    let user: UserModel
    let place: Place
    let category: String
    let content: String
    let imageUrl: String?
    let createdAt: Date
    let customLocation: Location?
    
    @Published var likeCount: Int
    @Published var commentCount: Int
    @Published var liked: Bool
    
    init(
        postId: PostId,
        user: UserModel,
        place: Place,
        category: String,
        content: String,
        imageUrl: String?,
        createdAt: Date,
        likeCount: Int,
        commentCount: Int,
        liked: Bool,
        customLocation: Location?
    ) {
        self.postId = postId
        self.user = user
        self.place = place
        self.category = category
        self.content = content
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.liked = liked
        self.customLocation = customLocation
    }
}


class UserModel: ObservableObject {
    let username: username
    let firstName: String
    let lastName: String
    let profilePictureUrl: String?
    
    @Published var postCount: Int
    @Published var followerCount: Int
    @Published var followingCount: Int
    
    init(
        username: username,
        firstName: String,
        lastName: String,
        profilePictureUrl: String?,
        postCount: Int,
        followerCount: Int,
        followingCount: Int
    ) {
        self.username = username
        self.firstName = firstName
        self.lastName = lastName
        self.profilePictureUrl = profilePictureUrl
        self.postCount = postCount
        self.followerCount = followerCount
        self.followingCount = followingCount
    }
}


class CommentModel: ObservableObject {
    let commentId: CommentId
    let user: UserModel
    let postId: PostId
    let content: String
    let createdAt: Date
    
    @Published var likeCount: Int
    @Published var liked: Bool
    
    init(
        commentId: CommentId,
        user: UserModel,
        postId: PostId,
        content: String,
        createdAt: Date,
        likeCount: Int,
        liked: Bool
    ) {
        self.commentId = commentId
        self.user = user
        self.postId = postId
        self.content = content
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.liked = liked
    }
}


struct NotificationItemModel {
    let type: ItemType
    let createdAt: Date
    let user: UserModel
    let itemId: String
    let post: PostModel?
    let comment: CommentModel?
}
