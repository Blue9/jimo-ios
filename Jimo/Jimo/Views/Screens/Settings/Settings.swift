//
//  Settings.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/13/21.
//

import SwiftUI
import Combine


class SettingsViewModel: ObservableObject {
    @Published var postNotifications: Bool = false
    @Published var likeNotifications: Bool = false
    @Published var followNotifications: Bool = false
    @Published var loading = true
    
    @Published var confirmSignOut = false
    
    var getPreferencesCancellable: Cancellable? = nil
    var setPreferencesCancellable: Cancellable? = nil
    
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
                  postLikedNotifications: likeNotifications,
                  postNotifications: postNotifications))
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
                viewState.setSuccess("Updated notification preferences!")
                self.setPreferences(preferences)
                self.loading = false
            })
    }
    
    private func setPreferences(_ preferences: UserPreferences) {
        self.postNotifications = preferences.postNotifications
        self.likeNotifications = preferences.postLikedNotifications
        self.followNotifications = preferences.followNotifications
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
                NavigationLink(destination: EditProfile()) {
                    Text("Edit profile")
                }
            }
            
            Section(header: Text("Notifications")) {
                Toggle(isOn: $settingsViewModel.followNotifications) {
                    VStack(alignment: .leading) {
                        Text("Follow notifications")
                        
                        Text("Get notified when someone follows you")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                
                Toggle(isOn: $settingsViewModel.likeNotifications) {
                    VStack(alignment: .leading) {
                        Text("Like notifications")
                        
                        Text("Get notified when someone likes your post")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                
                Toggle(isOn: $settingsViewModel.postNotifications) {
                    VStack(alignment: .leading) {
                        Text("Post notifications")
                        
                        Text("Get notified when someone you follow makes a new post")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                
                Button(action: {
                    settingsViewModel.updatePreferences(appState: appState, viewState: globalViewState)
                }) {
                    Text("Update notification preferences")
                }
            }
            .disabled(settingsViewModel.loading)
            
            Section(header: Text("Account")) {
                Button(action: { settingsViewModel.signOut() }) {
                    Text("Sign out")
                        .foregroundColor(.red)
                }
                Text("For additional support, please email help@jimoapp.com")
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
        .navigationBarColor(.white)
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavTitle("Settings")
            }
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Settings()
        }
        .environmentObject(AppState(apiClient: APIClient()))
        .environmentObject(GlobalViewState())
    }
}
