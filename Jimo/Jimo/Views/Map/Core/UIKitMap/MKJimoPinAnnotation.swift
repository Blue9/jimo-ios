//
//  MKJimoPinAnnotation.swift
//  Jimo
//
//  Created by Gautam Mekkat on 7/9/22.
//

import UIKit
import MapKit

/**
 Utility class to make it easier for the MapPin type to interact with MapKit primitives.
 */
class MKJimoPinAnnotation: NSObject, MKAnnotation, Identifiable {

    var id: String {
        "\(placeId ?? ""):\(category ?? ""):\(imageUrl ?? ""):\(numPosts)"
    }

    // This property must be key-value observable, which the `@objc dynamic` attributes provide.
    @objc dynamic var coordinate: CLLocationCoordinate2D

    var placeId: PlaceId?

    var category: String?

    var imageUrl: String?

    var numPosts: Int = 0

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }

    init(from pin: MapPin) {
        self.coordinate = pin.location.coordinate()
        self.placeId = pin.placeId
        self.category = pin.icon.category
        self.imageUrl = pin.icon.iconUrl
        self.numPosts = pin.icon.numPosts
        super.init()
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let annotation = object as? MKJimoPinAnnotation {
            return id == annotation.id
        }
        return false
    }

    public static func ==(lhs: MKJimoPinAnnotation, rhs: MKJimoPinAnnotation) -> Bool {
        return lhs.id == rhs.id
    }

    override var hash: Int {
        return id.hashValue
    }
}
