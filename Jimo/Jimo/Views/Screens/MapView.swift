//
//  MapView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import MapKit
import SwiftUI


struct CategoryFilterButton: View {
    var name: String
    var imageName: String
    var color: CGColor
    
    var body: some View {
        HStack {
            ZStack {
                VStack {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.vertical, 6)
                        .frame(width: 60, height: 30, alignment: .center)
                        .background(Color(color))
                        .cornerRadius(15)
                }
            }
        }
    }
}


struct MapSearch: View {
    @State var query: String = ""
    
    var body: some View {
        SearchBar(
            text: $query,
            minimal: true,
            placeholder: "Search places",
            textFieldColor: .init(white: 1, alpha: 0.4))
        .padding(.horizontal, 15)
        .padding(.top, 50)
        .padding(.bottom, 15)
    }
}


struct MapView: View {
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))

    @State var region: MKCoordinateRegion = defaultRegion
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region)
                .edgesIgnoringSafeArea(.all)
            VStack {
                MapSearch()
                    .background(Color.init(white: 1, opacity: 0.9))
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
            .environmentObject(AppState(apiClient: APIClient()))
    }
}
