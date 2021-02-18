//
//  Post.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import Foundation
import MapKit

typealias PostId = String

struct Post: Codable, Equatable, Identifiable {
    var id: PostId {
        postId
    }
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
    
    var location: CLLocationCoordinate2D {
        if let location = customLocation {
            return location.coordinate()
        } else {
            return place.location.coordinate()
        }
    }
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
