//
//  ProfileTab.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/7/21.
//

import SwiftUI

struct ProfileTab: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @StateObject private var settingsViewModel = SettingsViewModel()

    let currentUser: PublicUser?

    @State private var showSettings = false

    var body: some View {
        Navigator {
            if let currentUser = currentUser {
                Profile(initialUser: currentUser)
                    .background(Color("background"))
                    .navDestination(isPresented: $showSettings) {
                        Settings(settingsViewModel: settingsViewModel)
                            .environmentObject(appState)
                            .environmentObject(globalViewState)
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarColor(UIColor(Color("background")))
                    .navigationTitle(Text("Profile"))
                    .toolbar(content: {
                        ToolbarItem(placement: .navigationBarTrailing, content: {
                            Button(action: { self.showSettings = true }) {
                                Image(systemName: "gearshape")
                            }
                        })
                    })
                    .trackScreen(.profileTab)
            } else {
                AnonymousProfilePlaceholder()
                    .redacted(reason: .placeholder)
                    .overlay(ProfileSignUpNudge())
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle(Text("Profile"))
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                appState.signOut()
                            } label: {
                                Text("Sign out").foregroundColor(.blue)
                            }
                        }
                    }
            }
        }
    }
}

private struct ProfileSignUpNudge: View {
    @EnvironmentObject var viewState: GlobalViewState

    var body: some View {
        ZStack {
            Color("background").opacity(0.4)
            Button {
                viewState.showSignUpPage(.profile)
            } label: {
                Text("Sign up to create your profile")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
    }
}
