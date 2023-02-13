//
//  Onboarding.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/10/23.
//

import Foundation

struct PlaceTilePage: Codable, Equatable, Hashable {
    var places: [PlaceTile]
}

struct PlaceTile: Codable, Equatable, Hashable {
    var placeId: PlaceId
    var name: String
    var imageUrl: String
    var category: String
    var description: String
}

struct MinimalSavePlaceRequest: Codable, Equatable, Hashable {
    var placeId: PlaceId
}

struct MinimalCreatePostRequest: Codable, Equatable, Hashable {
    var placeId: PlaceId
    var category: String
    var stars: Int?
}

struct OnboardingCreateMultiRequest: Codable, Equatable, Hashable {
    var city: String?
    var posts: [MinimalCreatePostRequest]
    var saves: [MinimalSavePlaceRequest]
}
