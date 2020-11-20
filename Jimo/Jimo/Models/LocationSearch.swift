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

// From https://www.mozzafiller.com/posts/mklocalsearchcompleter-swiftui-combine
class LocationSearch: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    var completer: MKLocalSearchCompleter
    @Published var completions: [MKLocalSearchCompletion] = []
    var cancellable: AnyCancellable?
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        cancellable = $searchQuery.assign(to: \.queryFragment, on: self.completer)
        completer.delegate = self
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.completions = completer.results
//        self.completions = completer.results.filter { $0.subtitle.count > 0 }
    }
}

extension MKLocalSearchCompletion: Identifiable {}
