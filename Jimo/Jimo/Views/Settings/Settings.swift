//
//  Settings.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/13/21.
//

import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var postLikedNotifications: Bool = false
    @Published var postNotifications: Bool = false
    @Published var followNotifications: Bool = false
    @Published var commentNotifications: Bool = false
    @Published var commentLikedNotifications: Bool = false
    @Published var searchableByPhoneNumber: Bool = false
    @Published var loading = true

    @Published var confirmSignOut = false

    var getPreferencesCancellable: Cancellable?
    var setPreferencesCancellable: Cancellable?
    var deleteAccountCancellable: Cancellable?

    func loadPreferences(appState: AppState, viewState: GlobalViewState) {
        loading = true
        getPreferencesCancellable = appState.getPreferences()
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error when getting preferences", error)
                    viewState.setError("Failed to load preferences")
                }
            }, receiveValue: { [weak self] preferences in
                guard let self = self else {
                    return
                }
                self.setPreferences(preferences)
                self.loading = false
            })
    }

    func updatePreferences(appState: AppState, viewState: GlobalViewState) {
        loading = true
        setPreferencesCancellable = appState.updatePreferences(
            .init(followNotifications: followNotifications,
                  postLikedNotifications: postLikedNotifications,
                  postNotifications: postNotifications,
                  commentNotifications: commentNotifications,
                  commentLikedNotifications: commentLikedNotifications,
                  searchableByPhoneNumber: searchableByPhoneNumber))
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Error when setting preferences", error)
                    viewState.setError("Failed to update preferences")
                }
                self?.loading = false
            }, receiveValue: { [weak self] preferences in
                guard let self = self else {
                    return
                }
                viewState.setSuccess("Updated preferences!")
                self.setPreferences(preferences)
                self.loading = false
            })
    }

    func deleteAccount(appState: AppState, viewState: GlobalViewState) {
        deleteAccountCancellable = appState.deleteUser()
            .sink { completion in
                if case .failure = completion {
                    viewState.setError("Failed to delete account. Please try again, or reach out to help@jimoapp.com if the issue persists.")
                }
            } receiveValue: { response in
                if !response.success {
                    viewState.setError("Cannot delete this account at this time.")
                } else {
                    appState.signOutFirebase()
                }
            }
    }

    private func setPreferences(_ preferences: UserPreferences) {
        self.postLikedNotifications = preferences.postLikedNotifications
        self.postNotifications = preferences.postNotifications
        self.followNotifications = preferences.followNotifications
        self.commentNotifications = preferences.commentNotifications
        self.commentLikedNotifications = preferences.commentLikedNotifications
        self.searchableByPhoneNumber = preferences.searchableByPhoneNumber
    }

    func signOut() {
        confirmSignOut = true
    }
}

struct Settings: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState

    @StateObject private var settingsViewModel = SettingsViewModel()

    var body: some View {
        Form {
            Section(header: Text("Profile")) {
                NavigationLink {
                    EditProfile()
                } label: {
                    Text("Edit profile")
                }
            }

            Section(header: Text("Preferences")) {
                NavigationLink {
                    EditPreferences(settingsViewModel: settingsViewModel)
                } label: {
                    Text("Edit preferences")
                }
            }
            .disabled(settingsViewModel.loading)

            Section(header: Text("Account")) {
                NavigationLink {
                    Feedback()
                } label: {
                    Text("Submit feedback")
                }

                Button(action: { settingsViewModel.signOut() }) {
                    Text("Sign out")
                        .foregroundColor(.red)
                }

                Text("For additional support, please email support@jimoapp.com")
                    .foregroundColor(.gray)
                    .font(.caption)
            }
        }
        .onAppear {
            settingsViewModel.loadPreferences(appState: appState, viewState: globalViewState)
        }
        .alert(isPresented: $settingsViewModel.confirmSignOut) {
            Alert(title: Text("Sign out?"),
                  primaryButton: .destructive(Text("Sign out")) {
                    appState.signOut()
                  },
                  secondaryButton: .cancel())
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(Color("background")))
        .navigationTitle(Text("Settings"))
        .trackScreen(.settings)
    }
}
