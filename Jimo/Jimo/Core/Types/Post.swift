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
    var stars: Int?
    var media: [PostMediaItem]?
    var createdAt: Date
    var likeCount: Int
    var commentCount: Int
    var liked: Bool
    var saved: Bool

    var imageUrl: String? {
        media?.first?.url
    }

    var location: CLLocationCoordinate2D {
        place.location.coordinate()
    }

    var postUrl: URL {
        URL(string: "https://go.jimoapp.com/view-post?id=\(id)")!
    }
}

struct PostMediaItem: Codable, Equatable, Identifiable, Hashable {
    var id: String
    var blobName: String?
    var url: String
}

struct FeedResponse: Codable {
    var posts: [Post]
    var cursor: String?
}

struct CreatePostRequest: Codable {
    /// One of placeId and place must be specified
    var placeId: PlaceId?
    var place: MaybeCreatePlaceRequest?
    var category: String
    var content: String
    var stars: Int?
    var media: [String]
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
