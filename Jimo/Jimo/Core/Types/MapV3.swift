//
//  MapV3.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/20/22.
//

import Foundation

struct GetMapRequest: Codable, Equatable {
    var region: Region
    var categories: [String] = []
}

struct CustomMapRequest: Codable {
    var region: Region
    var categories: [String] = []
    var users: [String]
}

struct PlaceLoadRequest: Codable {
    var categories: [String] = []
}

struct CustomPlaceLoadRequest: Codable {
    var categories: [String] = []
    var users: [String]
}

struct MapPinV3: Identifiable, Codable, Equatable {
    var id: String {
        placeId
    }
    var placeId: String
    var location: Location
    var icon: MapPlaceIconV3
}

struct MapResponseV3: Codable, Equatable {
    var pins: [MapPinV3]
}
