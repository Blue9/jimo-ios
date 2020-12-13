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
    var content: String
    var imageUrl: String?
    var createdAt: Date
    var tags: [String] = []
    var likeCount: Int
    var commentCount: Int
}
