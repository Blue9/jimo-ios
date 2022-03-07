//
//  CurrentLocationButton.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/22/22.
//

import SwiftUI
import MapKit

struct CurrentLocationButton: View {
    var regionWrapper: RegionWrapper
    
    var locationManager: CLLocationManager
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation {
                if let location = locationManager.location {
                    regionWrapper.region.wrappedValue = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                    regionWrapper.trigger.toggle()
                } else {
                    print("Could not get location")
                }
            }
        }) {
            ZStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
                    .frame(width: 50, height: 50)
                    .background(Color("background"))
                    .cornerRadius(25)
                    .contentShape(Circle())
            }
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(radius: 3)
    }
}
