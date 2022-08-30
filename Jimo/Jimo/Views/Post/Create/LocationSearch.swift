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
                self.searchState = .autocomplete
                self.mkSearchResults.removeAll()
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
        completer = MKLocalSearchCompleter()
        super.init()
        cancellable = $searchQuery.assign(to: \.queryFragment, on: self.completer)
        completer.delegate = self
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results
        self.startedSearching = true
    }
    
    func search(query: String) {
        self.searchState = .search
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
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