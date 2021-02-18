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
    @Environment(\.backgroundColor) var backgroundColor
    @ObservedObject var profileVM: ProfileVM
    
    var body: some View {
        NavigationView {
            Profile(profileVM: profileVM)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarColor(UIColor(backgroundColor))
                .toolbar(content: {
                    ToolbarItem(placement: .principal) {
                        NavTitle("Profile")
                    }
                    ToolbarItem(placement: .navigationBarTrailing, content: {
                        NavigationLink(destination: Settings()
                                        .environmentObject(appState)
                                        .environmentObject(globalViewState)) {
                            Image(systemName: "gearshape")
                        }
                    })
                })
        }
    }
}

//struct ProfileTab_Previews: PreviewProvider {
//    static let model = AppModel()
//    
//    static var previews: some View {
//        ProfileTab(profileVM: ProfileVM(model: model, username: "gautam"))
//            .environmentObject(model)
//    }
//}
