//
//  MapV3.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/20/22.
//

import Foundation

struct RectangularRegion: Codable, Equatable, Hashable {
    var xMin: Double
    var yMin: Double
    var xMax: Double
    var yMax: Double
}

enum MapType: String, Codable {
    case community, following, saved, custom, me
}

struct GetMapRequest: Codable, Equatable {
    var region: RectangularRegion
    var categories: [String] = []
    var mapType: MapType
    var userIds: [String] = []
}

struct MapPin: Identifiable, Codable, Equatable {
    var id: String {
        placeId
    }
    var placeId: String
    var location: Location
    var icon: MapPinIcon
}

struct MapPinIcon: Codable, Equatable {
    var category: String?
    var iconUrl: String?
    var numPosts: Int
}

struct MapResponse: Codable, Equatable {
    var pins: [MapPin]
}
