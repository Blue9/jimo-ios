//
//  PostDestination.swift
//  Jimo
//
//  Created by Gautam Mekkat on 4/10/22.
//

import Foundation

enum PostDestination: Identifiable {
    case profile(PublicUser)
    case post(PostId)
    case map(PostId)

    var id: String {
        switch self {
        case .profile(let user):
            return "profile:\(user.id)"
        case .post(let postId):
            return "post:\(postId)"
        case .map(let postId):
            return "map:\(postId)"
        }
    }
}
