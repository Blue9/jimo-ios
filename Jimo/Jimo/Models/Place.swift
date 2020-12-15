//
//  Place.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/14/20.
//

import Foundation

typealias PlaceId = String

struct Place: Codable, Identifiable {
    let id = UUID()
    var placeId: PlaceId
    var category: String
    var location: Location
}

struct Location: Codable {
    var latitude: Double
    var longitude: Double
}
