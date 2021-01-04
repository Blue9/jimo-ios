//
//  Post.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import Foundation

typealias PostId = String

struct Post: Codable, Identifiable {
    let id = UUID()
    var postId: PostId
    var user: User
    var place: Place
    var category: String
    var content: String
    var imageUrl: String?
    //var createdAt: Date
    var likeCount: Int
    var customLocation: Location?
}


struct CreatePostRequest: Codable {
    var place: MaybeCreatePlaceRequest
    var category: String
    var content: String
    var imageUrl: String?
    var customLocation: Location?
}
