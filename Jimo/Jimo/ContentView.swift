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
    
    @Environment(\.backgroundColor) var backgroundColor
    
    var body: some View {
        ZStack {
            if case .loading = appState.firebaseSession {
                Image("logo")
            } else if case .doesNotExist = appState.firebaseSession {
                AuthView()
                    .transition(.slide)
            } else if case .loading = appState.currentUser {
                // Firebase user exists, loading user profile
                NavigationView {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .background(backgroundColor.edgesIgnoringSafeArea(.all))
                        .transition(.opacity)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarColor(UIColor(backgroundColor))
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                NavTitle("Loading profile")
                            }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Sign out") {
                                    appState.signOut()
                                }
                            }
                        }
                }
                .navigationViewStyle(StackNavigationViewStyle())
            } else if case .failed = appState.currentUser {
                // Firebase user exists, failed while loading user profile
                NavigationView {
                    VStack {
                        Spacer()
                        Button("Unable to connect to server. Tap here to try again.") {
                            appState.refreshCurrentUser()
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(backgroundColor.edgesIgnoringSafeArea(.all))
                    .transition(.opacity)
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarColor(UIColor(backgroundColor))
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            NavTitle("Loading profile")
                        }
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
                    profileVM: ProfileVM(appState: appState, globalViewState: globalViewState, user: user),
                    mapVM: MapViewModel(appState: appState, viewState: globalViewState)
                )
                .transition(.slide)
                .id(user) // Force view reset when current user changes (i.e., when updating profile)
            } else { // appState.currentUser == .empty
                // Firebase user exists, user profile does not exist
                NavigationView {
                    WaitlistView()
                        .navigationBarHidden(true)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .transition(.slide)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
        .popup(isPresented: $globalViewState.showError, type: .toast, position: .bottom, autohideIn: 2, closeOnTap: true, closeOnTapOutside: false) {
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
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear(perform: appState.listen)
    }
}

struct ContentView_Previews: PreviewProvider {
    static let api = APIClient()
    static var previews: some View {
        ContentView()
            .environmentObject(AppState(apiClient: api))
            .environmentObject(GlobalViewState())
    }
}
