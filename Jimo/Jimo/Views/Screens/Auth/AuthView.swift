//
//  AuthView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/25/20.
//

import SwiftUI


struct AuthView: View {
    var body: some View {
        NavigationView {
            HomeMenu()
                .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .environment(\.font, .system(size: 18))
    }
}

struct AuthView_Previews: PreviewProvider {
    static let apiClient = APIClient()
    static let appState = AppState(apiClient: apiClient)
    
    static var previews: some View {
        AuthView()
            .environmentObject(appState)
            .environmentObject(GlobalViewState())
    }
}
