//
//  MKCoordinateRegion+Equatable.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/6/21.
//

import Foundation
import MapKit

extension MKCoordinateRegion: Equatable {
    public static func ==(lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        return lhs.center == rhs.center && lhs.span == rhs.span
    }
}
