//
//  MapSearchResults.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/18/22.
//
import SwiftUI
import MapKit

struct MapSearchResults: View {
    @ObservedObject var locationSearch: LocationSearch
    @State private var showAlert = false

    var selectPlace: (MKMapItem) -> Void

    private func getAddress(mapItem: MKMapItem) -> String {
        let placemark = mapItem.placemark
        var streetAddress: String?
        if let subThoroughfare = placemark.subThoroughfare,
           let thoroughfare = placemark.thoroughfare {
            streetAddress = subThoroughfare + " " + thoroughfare
        }
        let components = [
            streetAddress,
            placemark.locality,
            placemark.administrativeArea
        ]
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
                                    self.selectPlace(places[0])
                                } else {
                                    self.locationSearch.mkSearchResults = places
                                }
                            } else {
                                self.showAlert = true
                            }
                        }
                    }
                }
            } footer: {
                HStack {
                    Spacer()
                    Text("Tap the Return key to view more results")
                    Spacer()
                }
                .font(.system(size: 15))
                .foregroundColor(.gray)
            }
        }
        .listRowBackground(Color.red)
        .listStyle(.plain)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Something went wrong."),
                message: Text("Try again or select another option."))
        }
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
                self.selectPlace(mapItem)
            }
        }
        .listRowBackground(Color.red)
        .listStyle(.plain)
    }

    var body: some View {
        Group {
            if locationSearch.searchState == .search {
                searchResults
            } else {
                autocompleteResults
            }
        }
    }
}
