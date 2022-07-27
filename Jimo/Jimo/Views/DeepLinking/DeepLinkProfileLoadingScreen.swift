//
//  DeepLinkProfileLoadingScreen.swift
//  Jimo
//
//  Created by Gautam Mekkat on 7/26/22.
//

import SwiftUI

/// This wrapper view loads the user, if we have not done so yet
struct DeepLinkProfileLoadingScreen: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @StateObject var viewModel = ViewModel()
    
    var username: String
    
    var body: some View {
        Group {
            if let user = viewModel.initialUser {
                ProfileScreen(initialUser: user)
            } else if viewModel.loadStatus == .notInitialized {
                ProgressView()
                    .onAppear {
                        viewModel.loadProfile(with: appState, viewState: viewState, username: username)
                    }
            } else {
                ProgressView()
                    .onAppear {
                        presentationMode.wrappedValue.dismiss()
                    }
            }
        }
        .background(Color("background"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarColor(UIColor(Color("background")))
        .toolbar(content: {
            ToolbarItem(placement: .principal) {
                NavTitle("Profile")
            }
        })
    }
}
