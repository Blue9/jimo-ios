//
//  CLLocationCoordinate2D+Equatable.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/6/21.
//

import Foundation
import MapKit

extension CLLocationCoordinate2D: Equatable {
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
