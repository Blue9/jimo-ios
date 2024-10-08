//
//  ProfileTab.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/7/21.
//

import SwiftUI
import PopupView

struct ProfileTab: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @StateObject private var navigationState = NavigationState()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var suggestedViewModel = SuggestedUserCarouselViewModel()
    @StateObject private var createPostVM = CreatePostVM()

    let currentUser: PublicUser?

    @State private var showCreatePost = false

    var body: some View {
        Navigator(state: navigationState) {
            mainBody
        }
        .environmentObject(appState)
        .environmentObject(globalViewState)
        .environmentObject(settingsViewModel)
    }

    @ViewBuilder var mainBody: some View {
        if let currentUser = currentUser {
            Profile(
                initialUser: currentUser,
                editPost: self.editPost(_:)
            )
            .sheet(isPresented: $showCreatePost, onDismiss: createPostVM.resetAll) {
                CreatePostWithModel(createPostVM: createPostVM, presented: $showCreatePost)
            }
            .background(Color("background"))
            // When swiping back from search users sometimes adds a black bar where keyboard would be
            // This fixes that (this didn't happen on profile, only feed, but this is extra safe
            .ignoresSafeArea(.keyboard, edges: .all)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarColor(UIColor(Color("background")))
            .navigationTitle(Text("My Profile"))
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        navigationState.push(.settings)
                    } label: {
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

    private func editPost(_ post: Post) {
        createPostVM.resetAll()
        createPostVM.initAsEditor(post)
        self.showCreatePost = true
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
