//
//  SearchViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/8/21.
//

import Foundation
import Combine
import MapKit

enum SearchType {
    case people
    case places
}


class SearchViewModel: ObservableObject {
    @Published var searchType: SearchType = .people
    @Published var query: String = ""
    @Published var userResults: [PublicUser] = []
    @Published var placeResults: [MKLocalSearchCompletion] = []
    
    @Published var selectedPlaceResult: MKMapItem?
    @Published var showPlaceResult: Bool = false
    
    private var locationSearch: LocationSearch = LocationSearch()
    
    private var userSearchCancellable: Cancellable? = nil
    private var placeSearchCancellable: Cancellable? = nil
    
    func listen(appState: AppState) {
        locationSearch.completer.resultTypes = [.address, .pointOfInterest]
        userSearchCancellable = $query
            .flatMap { [weak self] query -> AnyPublisher<String, Never> in
                if self?.searchType == .places {
                    return Empty().eraseToAnyPublisher()
                }
                return Just(query).eraseToAnyPublisher()
            }
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .flatMap { query -> AnyPublisher<[PublicUser], Never> in
                appState.searchUsers(query: query)
                    .catch { error -> AnyPublisher<[PublicUser], Never> in
                        print("Error when searching", error)
                        return Empty().eraseToAnyPublisher()
                    }
                    .eraseToAnyPublisher()
            }
            .sink { [weak self] users in
                self?.userResults = users
            }
        placeSearchCancellable = $query
            .flatMap({ [weak self] query -> AnyPublisher<String, Never> in
                if query.count == 0 {
                    self?.placeResults.removeAll()
                    return Empty().eraseToAnyPublisher()
                }
                if self?.searchType == .people {
                    return Empty().eraseToAnyPublisher()
                }
                return Just(query).eraseToAnyPublisher()
            })
            .flatMap({ [weak self] query -> AnyPublisher<[MKLocalSearchCompletion], Never> in
                guard let self = self else {
                    return Empty().eraseToAnyPublisher()
                }
                self.locationSearch.searchQuery = query
                return self.locationSearch.$completions.eraseToAnyPublisher()
            })
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] users in
                self?.placeResults = users
            })
    }
    
    func selectPlace(appState: AppState, completion: MKLocalSearchCompletion) {
        let localSearch = MKLocalSearch(request: .init(completion: completion))
        localSearch.start { [weak self] (response, error) in
            if let place = response?.mapItems.first {
                self?.selectedPlaceResult = place
                self?.showPlaceResult = true
            }
        }
    }
}
