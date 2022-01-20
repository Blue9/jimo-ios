//
//  SearchViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/8/21.
//

import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var searchBarFocused = false
    @Published var userResults: [PublicUser] = []
    
    private var queryCancellable: Cancellable?
    private var userSearchCancellable: Cancellable?
    
    func listen(appState: AppState) {
        userSearchCancellable = $query
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.search(appState: appState, query: query)
            }
    }
    
    private func search(appState: AppState, query: String) {
        queryCancellable = appState.searchUsers(query: query)
            .catch { error -> AnyPublisher<[PublicUser], Never> in
                print("Error when searching", error)
                return Empty().eraseToAnyPublisher()
            }
            .sink { [weak self] results in
                self?.userResults = results
            }
    }
}
