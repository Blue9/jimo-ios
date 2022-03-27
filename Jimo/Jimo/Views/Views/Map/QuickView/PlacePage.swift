//
//  PlacePage.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/17/22.
//

import SwiftUI
import MapKit

struct PlacePage: View {
    @ObservedObject var quickViewModel: QuickViewModel
    var locationManager: CLLocationManager
    var place: Place
    
    @State private var initialized = false
    @State private var mapItem: MKMapItem?
    
    var address: String? {
        guard let mapItem = mapItem else {
            return nil
        }
        let placemark = mapItem.placemark
        var streetAddress: String? = nil
        if let subThoroughfare = placemark.subThoroughfare,
           let thoroughfare = placemark.thoroughfare {
            streetAddress = subThoroughfare + " " + thoroughfare
        }
        let components = [
            streetAddress,
            placemark.locality,
            placemark.administrativeArea
        ];
        return components.compactMap({ $0 }).joined(separator: ", ")
    }
    
    var distanceMiles: String? {
        guard let location = locationManager.location else {
            return nil
        }
        let distanceMeters = location.distance(from: CLLocation(latitude: place.location.latitude, longitude: place.location.longitude))
        let distanceMiles = distanceMeters / 1609.34
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumSignificantDigits = 2
        formatter.decimalSeparator = "."
        formatter.groupingSeparator = ","
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(floatLiteral: distanceMiles))
    }
    
    private func openInGoogleMaps() {
        let scheme = "comgooglemaps://"
        let query = place.name.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? place.name
        let url = "\(scheme)?q=\(query)&center=\(place.location.latitude),\(place.location.longitude)"
        UIApplication.shared.open(URL(string: url)!)
    }
    
    private func openInAppleMaps() {
        let q = place.name.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? place.name
        let sll = "\(place.location.latitude),\(place.location.longitude)"
        let url = "http://maps.apple.com/?q=\(q)&sll=\(sll)&z=10"
        if let encoded = url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
           let url = URL(string: encoded) {
            UIApplication.shared.open(url)
        } else {
            print("URL not valid", url)
        }
    }
    
    private func openInMapsAction() {
        if (UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!)) {
            openInGoogleMaps()
        } else {
            openInAppleMaps()
        }
    }
    
    @ViewBuilder var placeDetails: some View {
        Group {
            if let address = address {
                Text(address)
                    .font(.caption)
                    .lineLimit(1)
                    .padding(.bottom, 5)
            }
            
            if let phoneNumber = mapItem?.phoneNumber {
                HStack(spacing: 0) {
                    Text("Phone number · ")
                    Button {
                        if let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text(phoneNumber).foregroundColor(.blue)
                    }

                }
                .lineLimit(1)
                .padding(.bottom, 2)
            }
            
            if let website = mapItem?.url, let host = website.host {
                HStack(spacing: 0) {
                    Text("Website · ")
                    Button {
                        UIApplication.shared.open(website)
                    } label: {
                        Text(host).foregroundColor(.blue)
                    }
                }
                .lineLimit(1)
                .padding(.bottom, 2)
            }
        }
        .font(.caption)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text(place.name)
                    .fontWeight(.heavy)
                    .font(.system(size: 18))
                
                if let distanceMiles = distanceMiles {
                    Text(" · \(distanceMiles) mi")
                        .opacity(0.75)
                }
                
                Spacer()
            }
            .font(.system(size: 18))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.bottom, 5)
            
            if !initialized {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                placeDetails
            }
            
            Spacer()
            
            HStack {
                Button {
                    openInMapsAction()
                } label: {
                    HStack {
                        Text("Open in Maps").font(.caption)
                        Image(systemName: "arrow.up.right.square")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height: 15)
                    }
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(2)
                }
            }
        }
        .font(.system(size: 15))
        .appear {
            if !self.initialized {
                self.initialized = true
                quickViewModel.getMapItem(place: place) { mapItem in
                    self.mapItem = mapItem
                }
            }
        }
    }
}
