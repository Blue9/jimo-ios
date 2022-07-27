//
//  DeactivatedProfileView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 7/6/22.
//

import SwiftUI

struct DeactivatedProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    var body: some View {
        NavigationView {
            deactivatedProfileView
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        NavTitle("Goodbye")
                    }
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    @ViewBuilder
    var deactivatedProfileView: some View {
        VStack(spacing: 50) {
            Text("Your account is marked for permanent deletion. Your data is not visible to anyone and will be permanently deleted in the next 24 hours.")
                .bold()
                .multilineTextAlignment(.center)
            
            Button {
                appState.signOut()
            } label: {
                Text("Sign out")
                    .foregroundColor(.white)
                    .frame(width: 100, height: 40)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Spacer()
            
            Text("Contact us at help@jimoapp.com")
        }
        .padding(.vertical, 100)
        .padding(.horizontal, 50)
    }
}
