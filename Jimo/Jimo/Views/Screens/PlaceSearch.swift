//
//  PlaceSearch.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/10/20.
//

import SwiftUI
import MapKit

struct PlaceSearch: View {
    @StateObject var locationSearch: LocationSearch = LocationSearch()
    
    @Binding var active: Bool
    @State var showAlert = false
    
    var selectPlace: (MKMapItem) -> Void
    
    func setupLocationSearch() {
        locationSearch.completer.resultTypes = [.address, .pointOfInterest]
//        locationSearch.completer.pointOfInterestFilter = .init(including: [
//            .amusementPark,
//            .aquarium,
//            .bakery,
//            .beach,
//            .brewery,
//            .cafe,
//            .campground,
//            .foodMarket,
//            .hotel,
//            .library,
//            .marina,
//            .movieTheater,
//            .museum,
//            .nationalPark,
//            .nightlife,
//            .park,
//            .restaurant,
//            .stadium,
//            .store,
//            .theater,
//            .winery,
//            .zoo
//        ])
    }
    
    init(active: Binding<Bool>, selectPlace: @escaping (MKMapItem) -> Void) {
        _active = active
        self.selectPlace = selectPlace
    }
    
    var body: some View {
        VStack {
            SearchBar(text: $locationSearch.searchQuery, placeholder: "Search for a place")
            List(locationSearch.completions) { completion in
                HStack {
                    VStack(alignment: .leading) {
                        Text(completion.title)
                        Text(completion.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    let localSearch = MKLocalSearch(request: .init(completion: completion))
                    localSearch.start { (response, error) in
                        guard error == nil else {
                            self.showAlert = true
                            return
                        }
                        let places = response?.mapItems
                        if places != nil && places!.count > 0 {
                            self.active = false
                            self.selectPlace(places![0])
                        } else {
                            self.showAlert = true
                        }
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Something went wrong."),
                        message: Text("Try again or select another option."))
                }
            }
        }
        .onAppear {
            self.setupLocationSearch()
        }
    }
}

struct PlaceSearch_Previews: PreviewProvider {
    @State static var active = true
    static var previews: some View {
        PlaceSearch(active: $active, selectPlace: {_ in })
    }
}
