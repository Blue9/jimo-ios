//
//  LocationSearch.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/10/20.
//

import Foundation
import SwiftUI
import MapKit
import Combine

enum SearchState: String {
    case autocomplete, search
}

// From https://www.mozzafiller.com/posts/mklocalsearchcompleter-swiftui-combine
class LocationSearch: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = "" {
        didSet {
            if searchQuery != oldValue {
                DispatchQueue.main.async {
                    self.searchState = .autocomplete
                    self.mkSearchResults.removeAll()
                }
            }
        }
    }
    @Published var completions: [MKLocalSearchCompletion] = []
    @Published var startedSearching = false
    @Published var mkSearchResults: [MKMapItem] = []
    
    @Published var searchState: SearchState = .autocomplete
    
    var completer: MKLocalSearchCompleter
    var cancellable: AnyCancellable?
    
    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        completer.resultTypes = [.address, .pointOfInterest]
        completer.delegate = self
        cancellable = $searchQuery.assign(to: \.queryFragment, on: self.completer)
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results
        self.startedSearching = true
    }
    
    func search() {
        self.searchState = .search
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        let search = MKLocalSearch(request: request)
        search.start { (response, _error) in
            let places = response?.mapItems
            if let places = places {
                self.mkSearchResults = places
            }
        }
    }
}

extension MKLocalSearchCompletion: Identifiable {}
