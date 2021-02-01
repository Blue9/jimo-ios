//
//  ViewPlace.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/28/21.
//

import SwiftUI
import MapKit

class PlaceViewModel: ObservableObject {
    let geocoder = CLGeocoder()
    let place: Place
    
    @Published var address = "Loading address..."
    
    init(place: Place) {
        self.place = place
    }
    
    func loadAddress() {
        print("Setting address")
        geocoder.reverseGeocodeLocation(
            CLLocation(
                latitude: place.location.latitude,
                longitude: place.location.longitude),
            completionHandler: { places, error in
                DispatchQueue.main.async {
                    print("Handling")
                    guard let places = places, places.count > 0 else {
                        self.address = "Failed to load address"
                        print(error.debugDescription)
                        return
                    }
                    print("Got places", places.count)
                    let placemark = places[0]
                    self.setAddress(placemark: placemark)
                }
            })
    }
    
    func setAddress(placemark: CLPlacemark) {
        let components = [
            placemark.name,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ]
        let filtered = components.compactMap({ $0 })
        address = filtered.joined(separator: ", ")
    }
}

struct ViewPlace: View {
    @ObservedObject var placeViewModel: PlaceViewModel
    
    var place: Place {
        placeViewModel.place
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(place.name)
                        .font(.title)
                        .bold()
                    
                    Text(placeViewModel.address)
                        .font(.title3)
                }
                
                Spacer()
            }
            
            Spacer()
        }
        .animation(nil)
        .padding()
        .onAppear {
            placeViewModel.loadAddress()
        }
    }
}

struct ViewPlace_Previews: PreviewProvider {
    static var previews: some View {
        ViewPlace(
            placeViewModel: PlaceViewModel(
                place: Place(placeId: "placeId", name: "Covent Garden", location: Location(coord: .init(latitude: 51.5117, longitude: -0.1240)))))
    }
}
