//
//  ContentView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    
    var body: some View {
        ZStack {
            if (!model.initialized) {
                Image("splash")
//                    .transition(.slide)
            } else if (model.firebaseSession == nil) {
                // Firebase user does not exist
                AuthView()
                    .transition(.slide)
            } else if (model.loadingUserProfile == .loading) {
                // Firebase user exists, loading user profile
                Text("Just a sec!")
                    .transition(.opacity)
            } else if (model.loadingUserProfile == .error) {
                // Firebase user exists, failed while loading user profile
                VStack {
                    Button("Unable to connect to server. Tap here to try again") {
                        model.loadCurrentUserProfile()
                    }
                    .transition(.opacity)
                    
                    Button("Tap here to sign out") {
                        model.signOut()
                    }
                    .transition(.opacity)
                }
            } else if (model.currentUser == nil && model.loadingUserProfile == .success) {
                // Firebase user exists, user profile does not exist
                CreateProfileView()
                    .transition(.slide)
            } else {
                // Both exist
                MainAppView(
                    profileVM: ProfileVM(model: model, username: model.currentUser!.username, user: model.currentUser!),
                    feedModel: FeedModel(model: model))
                    .transition(.slide)
            }
        }
        .onAppear(perform: model.listen)
    }
}

struct ContentView_Previews: PreviewProvider {
    static let sessionStore = SessionStore()
    static let model = AppModel()
    
    static var previews: some View {
        ContentView().environmentObject(model)
    }
}
