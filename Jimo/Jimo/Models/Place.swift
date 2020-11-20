//
//  Place.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/14/20.
//

import Foundation

typealias PlaceId = String

struct Place {
    var placeId: PlaceId
    var category: String
    var latitude: Double
    var longitude: Double
}
