//
//  FeaturedUserStore.swift
//  Jimo
//
//  Created by Gautam Mekkat on 3/14/21.
//

import SwiftUI
import Combine

class FeaturedUserStore: SuggestedUserStore {
    @Published var allUsers: [PublicUser] = []
    @Published var selectedUsernames: Set<String> = []
    @Published var loadingSuggestedUsers = true
    @Published var loadingSuggestedUsersError: Error?

    @Published var followingLoading = false
    @Published var followManyFailed = false

    private var getUsersCancellable: Cancellable?
    private var followUsersCancellable: Cancellable?

    func getExistingUsers(appState: AppState) {
        withAnimation {
            loadingSuggestedUsers = true
        }
        getUsersCancellable = appState.getFeaturedUsers()
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Error when getting featured users")
                    withAnimation {
                        self?.loadingSuggestedUsersError = error
                        self?.loadingSuggestedUsers = false
                    }
                }
            } receiveValue: { [weak self] users in
                withAnimation {
                    self?.allUsers = users
                    self?.selectAll()
                    self?.loadingSuggestedUsersError = nil
                    self?.loadingSuggestedUsers = false
                }
            }
    }

    func follow(appState: AppState) {
        withAnimation {
            followingLoading = true
        }
        followUsersCancellable = appState.followMany(usernames: Array(selectedUsernames))
            .sink { [weak self] completion in
                withAnimation {
                    self?.followingLoading = false
                    if case let .failure(error) = completion {
                        print("Error when following many", error)
                        self?.followManyFailed = true
                    }
                }
            } receiveValue: { [weak self] response in
                withAnimation {
                    if response.success {
                        appState.onboardingModel.step()
                        print("Set featured users onboarded")
                    } else {
                        self?.followManyFailed = true
                    }
                }
            }
    }

    func toggleSelected(for username: String) {
        if selectedUsernames.contains(username) {
            selectedUsernames.remove(username)
        } else {
            selectedUsernames.insert(username)
        }
    }

    func clearAll() {
        selectedUsernames.removeAll()
    }

    func selectAll() {
        selectedUsernames = Set(allUsers.map { $0.username })
    }
}
