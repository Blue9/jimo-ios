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
    
    let currentUser: PublicUser
    
    @State private var showSettings: Bool = false
    
    var body: some View {
        NavigationView {
            Profile(initialUser: currentUser)
                .background(Color("background"))
                .background(
                    NavigationLink(destination: Settings()
                                    .environmentObject(appState)
                                    .environmentObject(globalViewState), isActive: $showSettings) {})
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarColor(UIColor(Color("background")))
                .toolbar(content: {
                    ToolbarItem(placement: .principal) {
                        NavTitle("Profile")
                    }
                    ToolbarItem(placement: .navigationBarTrailing, content: {
                        Button(action: { self.showSettings.toggle() }) {
                            Image(systemName: "gearshape")
                        }
                    })
                })
                .trackScreen(.profileTab)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
