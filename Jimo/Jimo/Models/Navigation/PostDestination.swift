//
//  PostDestination.swift
//  Jimo
//
//  Created by Gautam Mekkat on 4/1/22.
//

import Foundation

enum PostDestination: Identifiable {
    case post(PostId)
    case profile(PublicUser)
    case map(PostId)
    
    var id: String {
        switch self {
        case .post(let postId):
            return "post:\(postId)"
        case .profile(let user):
            return "profile:\(user.id)"
        case .map(let postId):
            return "map:\(postId)"
        }
    }
}
