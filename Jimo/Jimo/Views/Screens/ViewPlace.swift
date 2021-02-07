//
//  ViewPlace.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/28/21.
//

import SwiftUI
import MapKit
import Combine

struct PlaceParams {
    let address: String
    let phoneNumber: String
    let website: String
}

struct ViewPlace: View {
    let place: Place?
    let mapItem: MKMapItem?
    
    @State private var placeParams = PlaceParams(
        address: "Loading address...",
        phoneNumber: "Loading phone number...",
        website: "Loading website...")
    @State private var setParams = false
    
    init(place: Place) {
        self.place = place
        self.mapItem = nil
    }
    
    init(mapItem: MKMapItem) {
        self.mapItem = mapItem
        self.place = nil
    }
    
    static func getAddress(placemark: CLPlacemark) -> String {
        var streetAddress: String? = nil
        if let subThoroughfare = placemark.subThoroughfare,
           let thoroughfare = placemark.thoroughfare {
            streetAddress = subThoroughfare + " " + thoroughfare
        }
        let components = [
            streetAddress,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country];
        return components
            .compactMap({ $0 })
            .joined(separator: ", ")
    }
    
    private func getAddress(place: Place, completionHandler: @escaping MKLocalSearch.CompletionHandler) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = place.name
        request.region = MKCoordinateRegion(
            center: place.location.coordinate(),
            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        let localSearch = MKLocalSearch(request: request)
        localSearch.start(completionHandler: completionHandler)
    }
    
    private func getParams(mapItem: MKMapItem) -> PlaceParams{
        return PlaceParams(
            address: ViewPlace.getAddress(placemark: mapItem.placemark),
            phoneNumber: mapItem.phoneNumber ?? "Unknown",
            website: mapItem.url?.absoluteString ?? "Unknown")
    }
    
    var name: String {
        if let place = place {
            return place.name
        } else if let mapItem = mapItem {
            return mapItem.name ?? ""
        }
        return ""
    }
    
    var location: CLLocationCoordinate2D? {
        if let place = place {
            return place.location.coordinate()
        } else if let mapItem = mapItem {
            return mapItem.placemark.coordinate
        }
        return nil
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(name)
                        .font(Font.custom(Poppins.semiBold, size: 20))
                        .bold()
                    Text(placeParams.address)
                }
                Spacer()
            }
            Divider()
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("Phone")
                        .foregroundColor(.gray)
                    
                    if setParams, let url = URL(string: "tel://\(placeParams.phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            Text(placeParams.phoneNumber)
                        }
                    } else {
                        Text(placeParams.phoneNumber)
                    }
                }
                Spacer()
            }
            Divider()
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("Website")
                        .foregroundColor(.gray)
                    if setParams, let url = URL(string: placeParams.website) {
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            Text(placeParams.website)
                        }
                    } else {
                        Text(placeParams.website)
                    }
                }
                Spacer()
            }
            Divider()
            Button(action: {
                let q = name.split(separator: " ").joined(separator: "+")
                var url: String
                if let location = location {
                    let sll = "\(location.latitude),\(location.longitude)"
                    url = "http://maps.apple.com/?q=\(q)&sll=\(sll)&z=10"
                } else {
                    url = "http://maps.apple.com/?q=\(q)&z=10"
                }
                if let url = URL(string: url) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open in Maps")
                    .font(Font.custom(Poppins.semiBold, size: 16))
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.init(.displayP3,
                                           red: 0.6,
                                           green: 0.6,
                                           blue: 0.6,
                                           opacity: 0.3))
                    .cornerRadius(15)
                    .padding(.horizontal, 20)
            }
            Spacer()
        }
        .font(Font.custom(Poppins.regular, size: 16))
        .padding()
        .onAppear {
            if let place = place {
                getAddress(place: place) { response, error in
                    guard let response = response,
                          let firstResult = response.mapItems.first else {
                        setParams = true
                        return
                    }
                    placeParams = getParams(mapItem: firstResult)
                    setParams = true
                }
            } else if let mapItem = mapItem {
                self.placeParams = getParams(mapItem: mapItem)
                self.setParams = true
            }
        }
    }
}

struct ViewPlace_Previews: PreviewProvider {
    static var previews: some View {
        ViewPlace(place: Place(placeId: "placeId", name: "Covent Garden", location: Location(coord: .init(latitude: 51.5117, longitude: -0.1240))))
    }
}
