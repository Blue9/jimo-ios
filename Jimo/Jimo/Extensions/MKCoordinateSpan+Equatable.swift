//
//  MKCoordinateSpan+Equatable.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/6/21.
//

import Foundation
import MapKit

extension MKCoordinateSpan: Equatable {
    public static func ==(lhs: MKCoordinateSpan, rhs: MKCoordinateSpan) -> Bool {
        return lhs.latitudeDelta == rhs.latitudeDelta && lhs.longitudeDelta == rhs.longitudeDelta
    }
}
