//
//  FeaturedUserStore.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/14/21.
//

import Foundation
import Combine

class FeaturedUserStore: SuggestedUserStore {
    @Published var allUsers: [PublicUser] = []
    @Published var selected: [PublicUser] = []
    @Published var loadingSuggestedUsers = false
    @Published var loadingSuggestedUsersError: Error? = nil
    
    @Published var followingLoading = false
    @Published var followManyFailed = false
    
    private var getUsersCancellable: Cancellable? = nil
    private var followUsersCancellable: Cancellable? = nil
    
    func getExistingUsers(appState: AppState) {
        loadingSuggestedUsers = true
        getUsersCancellable = appState.getSuggestedUsers()
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Error when getting featured users")
                    self?.loadingSuggestedUsersError = error
                    self?.loadingSuggestedUsers = false
                }
            } receiveValue: { [weak self] users in
                self?.allUsers = users
                self?.selected = users
                self?.loadingSuggestedUsersError = nil
                self?.loadingSuggestedUsers = false
            }
    }
    
    func follow(appState: AppState) {
        followingLoading = true
        let toFollow = selected.compactMap({ $0.username })
        followUsersCancellable = appState.followMany(usernames: toFollow)
            .sink { [weak self] completion in
                self?.followingLoading = false
                if case let .failure(error) = completion {
                    print("Error when following many", error)
                    self?.followManyFailed = true
                }
            } receiveValue: { [weak self] response in
                if response.success {
                    appState.onboardingModel.setFeaturedUsersOnboarded()
                    print("Set featured users onboarded")
                } else {
                    self?.followManyFailed = true
                }
            }
    }
    
    func toggleSelected(for contact: PublicUser) {
        if selected.contains(contact) {
            selected.removeAll { contact == $0 }
        } else {
            selected.append(contact)
        }
    }
    
    func clearAll() {
        selected.removeAll()
    }
    
    func selectAll() {
        selected = allUsers
    }
}
