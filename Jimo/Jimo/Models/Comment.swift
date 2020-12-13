//
//  Comment.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/9/20.
//

import Foundation


struct Comment: Codable, Identifiable {
    let id = UUID()
    var commentId: String
    var user: User
    var postId: String
    var content: String
    var createdAt: Date
}
