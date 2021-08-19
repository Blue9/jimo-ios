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
    
    private var userSearchCancellable: Cancellable?
    
    func listen(appState: AppState) {
        userSearchCancellable = $query
            .debounce(for: 0.25, scheduler: DispatchQueue.main)
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
    }
}
