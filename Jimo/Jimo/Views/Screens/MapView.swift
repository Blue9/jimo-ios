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


struct Filter: View {
    @State var filterText: String = ""
    
    var body: some View {
        VStack {
            AnyView(
                SearchBar(
                    text: $filterText,
                    minimal: true,
                    placeholder: "Filter pins by name",
                    textFieldColor: .init(white: 1, alpha: 0.4))
                .padding(.horizontal, 15))
            HStack(spacing: 20) {
                CategoryFilterButton(name: "Food", imageName: "food", color: #colorLiteral(red: 0.9450980392, green: 0.4941176471, blue: 0.3960784314, alpha: 1))
                CategoryFilterButton(name: "Activity", imageName: "activity", color: #colorLiteral(red: 0.6, green: 0.7333333333, blue: 0.3137254902, alpha: 1))
                CategoryFilterButton(name: "Attraction", imageName: "attractions", color: #colorLiteral(red: 0.3294117647, green: 0.7254901961, blue: 0.7098039216, alpha: 1))
                CategoryFilterButton(name: "Lodging", imageName: "lodging", color: #colorLiteral(red: 0.9843137255, green: 0.7294117647, blue: 0.462745098, alpha: 1))
                CategoryFilterButton(name: "Shopping", imageName: "shopping", color: #colorLiteral(red: 1, green: 0.6, blue: 0.7568627451, alpha: 1))
            }
        }
        .padding(.top, 50)
        .padding(.bottom, 15)
    }
}


struct MapView: View {
    @State var region: MKCoordinateRegion = defaultRegion
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Filter()
                    .background(Color.init(white: 1, opacity: 0.8))
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView()
    }
}
