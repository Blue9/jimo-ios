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
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var suggestedViewModel = SuggestedUserCarouselViewModel()

    let currentUser: PublicUser?

    @State private var showSettings = false
    @State private var showSearchUsers = false

    var body: some View {
        Navigator {
            if let currentUser = currentUser {
                Profile(initialUser: currentUser)
                    .background(Color("background"))
                    // When swiping back from search users sometimes adds a black bar where keyboard would be
                    // This fixes that (this didn't happen on profile, only feed, but this is extra safe
                    .ignoresSafeArea(.keyboard, edges: .all)
                    .navDestination(isPresented: $showSettings) {
                        Settings(settingsViewModel: settingsViewModel)
                            .environmentObject(appState)
                            .environmentObject(globalViewState)
                    }
                    .navDestination(isPresented: $showSearchUsers) {
                        SearchUsers()
                            .environmentObject(appState)
                            .environmentObject(globalViewState)
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarColor(UIColor(Color("background")))
                    .navigationTitle(Text("My Profile"))
                    .toolbar(content: {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { self.showSearchUsers = true }) {
                                Image(systemName: "magnifyingglass")
                                    .contentShape(Rectangle())
                            }
                        }

                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { self.showSettings = true }) {
                                Image(systemName: "gearshape")
                            }
                        }
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

    @ViewBuilder
    func profilePicture(user: PublicUser) -> some View {
        URLImage(url: user.profilePictureUrl, loading: Image(systemName: "person.crop.circle"))
            .frame(width: 40, height: 40, alignment: .center)
            .font(Font.title.weight(.ultraLight))
            .foregroundColor(.gray)
            .background(Color.white)
            .cornerRadius(50)
            .padding(.trailing)
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
