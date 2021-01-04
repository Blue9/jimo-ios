//
//  Place.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/14/20.
//

import Foundation
import MapKit

typealias PlaceId = String

struct Place: Codable, Identifiable {
    let id = UUID()
    var placeId: PlaceId
    var name: String
    var location: Location
}

struct Location: Codable {
    var latitude: Double
    var longitude: Double
    
    init(coord: CLLocationCoordinate2D) {
        self.latitude = coord.latitude
        self.longitude = coord.longitude
    }
}

struct Region: Codable {
    var latitude: Double
    var longitude: Double
    var radius: Double
    
    init(coord: CLLocationCoordinate2D, radius: Double) {
        self.latitude = coord.latitude
        self.longitude = coord.longitude
        self.radius = radius
    }
}

struct MaybeCreatePlaceRequest: Codable {
    var name: String
    var location: Location
    var region: Region?
}
