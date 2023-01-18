//
//  ContentView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.colorScheme) var colorScheme

    @StateObject var networkMonitor = NetworkConnectionMonitor()

    var body: some View {
        ZStack {
            if case .loading = appState.firebaseSession {
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .offset(y: -5)
            } else if case .loading = appState.currentUser {
                // Firebase user exists, loading user profile
                Image("icon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .offset(y: -5)
            } else if case .doesNotExist = appState.firebaseSession {
                NavigationView {
                    HomeMenu().navigationBarHidden(true)
                }
                .navigationViewStyle(StackNavigationViewStyle())
            } else if case .failed = appState.currentUser {
                // Firebase user exists, failed while loading user profile
                NavigationView {
                    VStack {
                        Spacer()
                        Button("Could not connect. Tap to try again.") {
                            appState.refreshCurrentUser()
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationTitle(Text("Loading profile"))
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Sign out") {
                                appState.signOut()
                            }
                        }
                    }
                }
                .navigationViewStyle(StackNavigationViewStyle())
            } else if case let .user(user) = appState.currentUser {
                // Both exist
                LoggedInView(
                    onboardingModel: appState.onboardingModel,
                    currentUser: user
                )
                .id(user) // Force view reset when current user changes (i.e., when updating profile)
            } else if case .deactivated = appState.currentUser {
                DeactivatedProfileView()
            } else { // appState.currentUser == .empty
                // Firebase user exists, user profile does not exist
                NavigationView {
                    CreateProfileView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .popup(isPresented: !$networkMonitor.connected, type: .toast, position: .bottom, autohideIn: nil, closeOnTap: true) {
            Toast(text: "No internet connection", type: .error)
        }
        .popup(isPresented: $globalViewState.showError, type: .toast, position: .bottom, autohideIn: 4, closeOnTap: true, closeOnTapOutside: false) {
            Toast(text: globalViewState.errorMessage, type: .error)
                .padding(.bottom, 50)
        }
        .popup(isPresented: $globalViewState.showWarning, type: .toast, position: .bottom, autohideIn: 2, closeOnTap: true, closeOnTapOutside: false) {
            Toast(text: globalViewState.warningMessage, type: .warning)
                .padding(.bottom, 50)
        }
        .popup(isPresented: $globalViewState.showSuccess, type: .toast, position: .bottom, autohideIn: 2, closeOnTap: true, closeOnTapOutside: false) {
            Toast(text: globalViewState.successMessage, type: .success)
                .padding(.bottom, 50)
        }
        .shareOverlay(globalViewState.shareAction, isPresented: $globalViewState.showShareOverlay)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            appState.listen()
            networkMonitor.listen()
        }
    }
}
