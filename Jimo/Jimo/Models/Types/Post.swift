//
//  Post.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import Foundation
import MapKit

typealias PostId = String

struct Post: Codable, Equatable, Identifiable, Hashable {
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
    var commentCount: Int
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


struct FeedResponse: Codable {
    var posts: [Post]
    var cursor: String?
}


struct CreatePostRequest: Codable {
    var place: MaybeCreatePlaceRequest
    var category: String
    var content: String
    var imageId: String?
    var customLocation: Location?
}

struct DeletePostResponse: Codable {
    var deleted: Bool
}

struct LikePostResponse: Codable {
    var likes: Int
}

struct ReportPostRequest: Codable {
    var details: String?
}
