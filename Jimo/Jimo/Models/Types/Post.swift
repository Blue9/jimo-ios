//
//  Post.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import Foundation

typealias PostId = String

struct Post: Codable, Equatable, Identifiable {
    let id = UUID()
    var postId: PostId
    var user: PublicUser
    var place: Place
    var category: String
    var content: String
    var imageUrl: String?
    var createdAt: Date
    var likeCount: Int
    var liked: Bool
    var customLocation: Location?
}


struct CreatePostRequest: Codable {
    var place: MaybeCreatePlaceRequest
    var category: String
    var content: String
    var imageUrl: String?
    var customLocation: Location?
}

struct DeletePostResponse: Codable {
    var deleted: Bool
}

struct LikePostResponse: Codable {
    var likes: Int
}
