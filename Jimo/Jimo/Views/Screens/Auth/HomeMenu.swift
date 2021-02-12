//
//  HomeMenu.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/3/21.
//

import SwiftUI

struct RaisedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .shadow(radius: 4, x: 0.0, y: configuration.isPressed ? 0 : 4)
            .offset(y: configuration.isPressed ? 4 : 0)
            .animation(.easeIn(duration: 0.1), value: configuration.isPressed)
    }
}

struct HomeMenu: View {
    var body: some View {
        VStack {
            ZStack(alignment: .bottomTrailing) {
                Image("logo")
                    .aspectRatio(contentMode: .fit)
                    .padding(.bottom, 12)
                Text("beta")
            }
            .padding(.bottom, 40)
            
            VStack(alignment: .leading, spacing: 20) {
                Text("We can’t wait to get jimo out to the world, but for now we’re invite only.")
                
                Text("If you don’t have access, join our waitlist and we’ll add you as soon as we can!")
            }
            .frame(maxWidth: 280)
            .padding(.bottom, 40)
            
            
            NavigationLink(destination: EnterPhoneNumber()) {
                Text("Join Waitlist")
                    .font(Font.custom(Poppins.medium, size: 24))
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 60)
                    .foregroundColor(.white)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding(.bottom, 5)
            .buttonStyle(RaisedButtonStyle())
            
            NavigationLink(destination: EnterPhoneNumber()) {
                Text("Already have an invite? Sign in")
                    .font(Font.custom(Poppins.medium, size: 16))
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .foregroundColor(.red)
            }
            
            Spacer()
                .frame(maxHeight: 50)
        }
        .padding(.horizontal, 50)
        .frame(maxHeight: .infinity)
        // This fixes a bug when moving back from EnterPhoneNumber with the keyboard open
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background(Wave())
    }
}

struct HomeMenu_Previews: PreviewProvider {
    static var previews: some View {
        HomeMenu()
            .environmentObject(AppState(apiClient: APIClient()))
            .environmentObject(GlobalViewState())
            .environment(\.font, Font.custom(Poppins.medium, size: 18))
    }
}
