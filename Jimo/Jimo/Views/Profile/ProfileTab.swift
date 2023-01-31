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

    let currentUser: PublicUser

    @State private var showSettings = false

    var body: some View {
        Navigator {
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
        }
    }
}
