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
                    .navDestination(isPresented: $showSettings) {
                        Settings(settingsViewModel: settingsViewModel)
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
                    .fullScreenCover(isPresented: $showSearchUsers) {
                        SearchUsers()
                            .environmentObject(appState)
                            .environmentObject(globalViewState)
                    }
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
    var userResults: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading) {
                Divider()
                ForEach(searchViewModel.userResults, id: \.username) { (user: PublicUser) in
                    NavigationLink {
                        ProfileScreen(initialUser: user)
                    } label: {
                        HStack {
                            profilePicture(user: user)

                            VStack(alignment: .leading) {
                                Text(user.username)
                                    .font(.system(size: 15))
                                    .bold()
                                Text(user.firstName + " " + user.lastName)
                                    .font(.system(size: 15))
                            }
                            .foregroundColor(Color("foreground"))
                            Spacer()

                            Image(systemName: "arrow.right.circle")
                        }
                        .contentShape(Rectangle())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 2)
                    }
                    Divider()
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
