//
//  CreatePostVM.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/10/21.
//

import SwiftUI
import Combine
import MapKit

enum CreatePostActiveSheet: String, Identifiable {
    case placeSearch, imagePicker
    
    var id: String {
        self.rawValue
    }
}

class CreatePostVM: ObservableObject {
    var cancellable: Cancellable?
    
    @Published var activeSheet: CreatePostActiveSheet?
    
    /// Used for navigation links
    @Published var placeSearchActive = false
    
    /// Photo selection
    @Published var showImagePicker = false
    @Published var image: UIImage?
    
    // Sent to server
    @Published var name: String?
    
    /// Set when user searches and selects a location
    @Published var selectedLocation: MKMapItem?
    
    var locationString: String? {
        selectedPlaceAddress
    }
    
    var selectedPlaceAddress: String? {
        /// For whatever reason, the default placemark title is "United States"
        /// Example: Mount Everest Base Camp has placemark title "United States"
        /// WTF Apple
        if selectedLocation?.placemark.title == "United States" {
            return "View on map"
        }
        return selectedLocation?.placemark.title
    }
    
    var maybeCreatePlaceRequest: MaybeCreatePlaceRequest? {
        guard let name = name, let location = selectedLocation else {
            return nil
        }
        var region: Region? = nil
        if let area = location.placemark.region as? CLCircularRegion {
            region = Region(coord: location.placemark.coordinate, radius: area.radius.magnitude)
        }
        return MaybeCreatePlaceRequest(
            name: name,
            location: Location(coord: location.placemark.coordinate),
            region: region,
            additionalData: AdditionalPlaceDataRequest(location)
        )
    }
    
    func selectPlace(placeSelection: MKMapItem) {
        name = placeSelection.name
        selectedLocation = placeSelection
    }
    
    func resetPlace() {
        name = nil
        selectedLocation = nil
    }
}
