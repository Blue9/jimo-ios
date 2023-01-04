//
//  RegionWrapper.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/22/22.
//

import SwiftUI
import MapKit


/// When using a regular @Binding panning the map is super laggy with a lot of pins
/// (think the view gets rebuilt as the region value changes, so the annotations keep
/// getting added, not sure). This class creates a region binding but allows us to change the value without
/// triggering the binding.
class RegionWrapper: ObservableObject {
    @Published var trigger = false
    var _region: MKCoordinateRegion = defaultRegion
    
    var region: Binding<MKCoordinateRegion> {
        Binding(
            get: { self._region },
            set: { self._region = $0 }
        )
    }
    
    func setRegion(_ region: MKCoordinateRegion) {
        self._region = region
        self.trigger.toggle()
    }
}

fileprivate var defaultRegion = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 37, longitude: -96),
    span: MKCoordinateSpan(latitudeDelta: 85, longitudeDelta: 61))
