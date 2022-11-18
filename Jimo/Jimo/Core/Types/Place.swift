//
//  Place.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/14/20.
//

import Foundation
import MapKit

typealias PlaceId = String

struct Place: Identifiable, Codable, Equatable, Hashable {
    var id: PlaceId {
        placeId
    }
    var placeId: PlaceId
    var name: String
    var regionName: String?
    var location: Location
}

struct Location: Codable, Equatable, Hashable {
    var latitude: Double
    var longitude: Double
    
    init(coord: CLLocationCoordinate2D) {
        self.latitude = coord.latitude
        self.longitude = coord.longitude
    }
    
    func coordinate() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Region: Codable, Equatable {
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
    var additionalData: AdditionalPlaceDataRequest?
}

struct AdditionalPlaceDataRequest: Codable {
    var countryCode: String?
    var country: String?
    var postalCode: String?
    var administrativeArea: String?
    var subAdministrativeArea: String?
    var locality: String?
    var subLocality: String?
    var thoroughfare: String?
    var subThoroughfare: String?
    var poiCategory: String?
    var phoneNumber: String?
    var url: String?
    var timeZone: String?
    
    init(_ mapItem: MKMapItem) {
        let placemark = mapItem.placemark
        countryCode = placemark.countryCode
        country = placemark.country
        postalCode = placemark.postalCode
        administrativeArea = placemark.administrativeArea
        subAdministrativeArea = placemark.subAdministrativeArea
        locality = placemark.locality
        subLocality = placemark.subLocality
        thoroughfare = placemark.thoroughfare
        subThoroughfare = placemark.subThoroughfare
        poiCategory = mapItem.pointOfInterestCategory?.rawValue
        phoneNumber = mapItem.phoneNumber
        url = mapItem.url?.absoluteString
        timeZone = mapItem.timeZone?.description
    }
}

struct MapResponse: Codable, Equatable {
    var posts: [Post]
    var postCursorsByUser: [UserId: PostId]
}

struct MapPlaceIcon: Codable, Equatable {
    var category: String?
    var iconUrl: String?
    var numMutualPosts: Int
}

struct MapPlaceIconV3: Codable, Equatable {
    var category: String?
    var iconUrl: String?
    var numPosts: Int
}

struct MapPlace: Identifiable, Codable, Equatable {
    var id: String {
        place.id
    }
    var place: Place
    var icon: MapPlaceIcon
    var posts: [PostId] = []
}
