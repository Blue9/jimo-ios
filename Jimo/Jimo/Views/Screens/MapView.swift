//
//  MapView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import MapKit
import SwiftUI


let defaultRegion = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))


struct MapView: View {
    @State var region: MKCoordinateRegion = defaultRegion

    var body: some View {
        Map(coordinateRegion: $region)
            .edgesIgnoringSafeArea(.all)
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
