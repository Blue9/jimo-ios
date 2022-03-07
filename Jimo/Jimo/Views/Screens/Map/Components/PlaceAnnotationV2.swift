//
//  PlaceAnnotationV2.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/22/22.
//

import Foundation
import MapKit

class PlaceAnnotationV2: NSObject, MKAnnotation {
    let pin: MapPinV3
    let zIndex: Int
    
    var coordinate: CLLocationCoordinate2D {
        let coordinate = pin.location.coordinate()
        if coordinate.latitude == 0 && coordinate.longitude == 0 {
            // For some reason annotations at exactly (0, 0) don't appear on the map
            return .init(latitude: Double.leastNormalMagnitude, longitude: Double.leastNormalMagnitude)
        } else {
            return coordinate
        }
    }
    
    init(pin: MapPinV3, zIndex: Int) {
        self.pin = pin
        self.zIndex = zIndex
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let placeAnnotation = object as? PlaceAnnotationV2 {
            return pin == placeAnnotation.pin
        }
        return false
    }
    
    override var hash: Int {
        return coordinate.latitude.hashValue ^ coordinate.longitude.hashValue
    }
}
