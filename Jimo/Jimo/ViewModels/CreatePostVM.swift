//
//  CreatePostVM.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/10/21.
//

import SwiftUI
import Combine
import MapKit

class CreatePostVM: ObservableObject {
    var mapRegion: MKCoordinateRegion {
        let location = useCustomLocation ? customLocation : selectedLocation
        if let place = location {
            return MKCoordinateRegion(
                center: place.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        } else {
            return MapView.defaultRegion
        }
    }
    
    var cancellable: Cancellable? = nil

    @Published var useCustomLocation = false
    
    /// Used for navigation links
    @Published var placeSearchActive = false
    @Published var locationSearchActive = false
    
    /// Photo selection
    @Published var showImagePicker = false
    @Published var image: UIImage?
    
    // Sent to server
    @Published var name: String? = nil
    
    /// Set when user searches and selects a location
    @Published var selectedLocation: MKPlacemark? = nil
    
    /// Set when user selects a custom location
    @Published var customLocation: MKPlacemark? = nil
    
    var locationString: String? {
        return useCustomLocation ? "Custom location (View on map)" : selectedPlaceAddress
    }
    
    var selectedPlaceAddress: String? {
        /// For whatever reason, the default placemark title is "United States"
        /// Example: Mount Everest Base Camp has placemark title "United States"
        /// WTF Apple
        if selectedLocation?.title == "United States" {
            return "View on map"
        }
        return selectedLocation?.title
    }
    
    var maybeCreatePlaceRequest: MaybeCreatePlaceRequest? {
        guard let name = name, let location = selectedLocation else {
            return nil
        }
        var region: Region? = nil
        if let placemark = selectedLocation,
           let area = placemark.region as? CLCircularRegion {
            region = Region(coord: placemark.coordinate, radius: area.radius.magnitude)
        }
        return MaybeCreatePlaceRequest(name: name, location: Location(coord: location.coordinate), region: region)
    }
    
    func selectPlace(placeSelection: MKMapItem) {
        useCustomLocation = false
        selectedLocation = placeSelection.placemark
        name = placeSelection.name
    }
    
    func selectLocation(selectionRegion: MKCoordinateRegion) {
        customLocation = MKPlacemark(coordinate: selectionRegion.center)
        useCustomLocation = true
    }
    
    func resetName() {
        name = nil
    }
    
    func resetLocation() {
        if useCustomLocation {
            useCustomLocation = false
            customLocation = nil
        } else {
            // Either there is no searched location or we are already on it
            // In that case clear the location and the search
            selectedLocation = nil
        }
    }
}
