//
//  RegionWrapper.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/22/22.
//

import SwiftUI
import MapKit


class RegionWrapper: ObservableObject {
    var _region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37, longitude: -96),
        span: MKCoordinateSpan(latitudeDelta: 85, longitudeDelta: 61))
    
    var region: Binding<MKCoordinateRegion> {
        Binding(
            get: { self._region },
            set: { self._region = $0 }
        )
    }
    
    @Published var trigger = false
}
