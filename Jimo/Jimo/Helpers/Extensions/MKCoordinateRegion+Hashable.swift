//
//  MKCoordinateRegion+Hashable.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/30/22.
//

import Foundation
import MapKit


extension MKCoordinateRegion: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(center.latitude)
        hasher.combine(center.longitude)
        hasher.combine(span.latitudeDelta)
        hasher.combine(span.longitudeDelta)
    }
}
