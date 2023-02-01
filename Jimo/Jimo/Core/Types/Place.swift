//
//  Place.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/14/20.
//

import Foundation
import MapKit

typealias PlaceId = String

struct PingLocationRequest: Codable, Equatable, Hashable {
    var location: Location
}

struct Place: Identifiable, Codable, Equatable, Hashable {
    var id: PlaceId {
        placeId
    }
    var placeId: PlaceId
    var name: String
    var city: String?
    var category: String?
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

struct MaybeCreatePlaceRequest: Codable, Equatable {
    var name: String
    var location: Location
    var region: Region?
    var additionalData: AdditionalPlaceDataRequest?
}

struct AdditionalPlaceDataRequest: Codable, Equatable {
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

struct FindPlaceResponse: Codable, Equatable {
    var place: Place?
}

struct GetPlaceDetailsResponse: Codable, Equatable {
    var place: Place
    var myPost: Post?
    var mySave: SavedPlace?
    var followingPosts: [Post] = []
    var featuredPosts: [Post] = []
    var communityPosts: [Post] = []
}

struct SavedPlace: Identifiable, Codable, Equatable {
    var id: String
    var place: Place
    var note: String
    var createdAt: Date
}

struct SavedPlacesResponse: Codable, Equatable {
    var saved: [SavedPlace]
    var cursor: String?
}

struct SavePlaceRequest: Codable {
    var place: MaybeCreatePlaceRequest?
    var placeId: PlaceId?
    var note: String
}

struct SavePlaceResponse: Codable {
    var save: SavedPlace
    var createPlaceRequest: MaybeCreatePlaceRequest?
}
