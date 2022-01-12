//
//  PlaceSearch.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/10/20.
//

import SwiftUI
import MapKit

struct PlaceSearch: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var locationSearch: LocationSearch = LocationSearch()
    @State private var showAlert = false
    @State private var searchBarFocused = false
    
    var selectPlace: (MKMapItem) -> Void
    
    func setupLocationSearch() {
        locationSearch.completer.resultTypes = [.address, .pointOfInterest]
    }
    
    private func getAddress(mapItem: MKMapItem) -> String {
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
    
    @ViewBuilder private var autocompleteResults: some View {
        List {
            Section {
                ForEach(locationSearch.completions) { completion in
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
                            if let places = places, places.count > 0 {
                                if places.count == 1 {
                                    presentationMode.wrappedValue.dismiss()
                                    self.selectPlace(places[0])
                                } else {
                                    self.locationSearch.mkSearchResults = places
                                }
                            } else {
                                self.showAlert = true
                            }
                        }
                    }
                    .listRowBackground(Color("background"))
                }
            } footer: {
                if locationSearch.startedSearching {
                    HStack {
                        Spacer()
                        Text("Tap the Return key to view more results")
                        Spacer()
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .listRowBackground(Color("background"))
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Something went wrong."),
                message: Text("Try again or select another option."))
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder private var searchResults: some View {
        List(locationSearch.mkSearchResults, id: \.self) { (mapItem: MKMapItem) in
            HStack {
                VStack(alignment: .leading) {
                    if let name = mapItem.name {
                        Text(name)
                        Text(mapItem.placemark.title ?? getAddress(mapItem: mapItem))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                presentationMode.wrappedValue.dismiss()
                self.selectPlace(mapItem)
            }
            .listRowBackground(Color("background"))
        }
        .listStyle(.plain)
    }
    
    var body: some View {
        VStack {
            ZStack(alignment: .center) {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Cancel")
                            .padding(.horizontal, 15)
                    }
                    Spacer()
                }
                
                NavTitle("Name")
            }
            .padding(.top, 15)
            .padding(.bottom, 10)
            
            SearchBar(
                text: $locationSearch.searchQuery,
                isActive: $searchBarFocused,
                placeholder: "Search for a place",
                onCommit: {
                    locationSearch.search(query: locationSearch.searchQuery)
                }
            )
            if locationSearch.searchState == .search {
                searchResults
            } else {
                autocompleteResults
            }
            
            Spacer()
        }
        .foregroundColor(Color("foreground"))
        .background(Color("background").edgesIgnoringSafeArea(.all))
        .onAppear {
            self.setupLocationSearch()
        }
    }
}
