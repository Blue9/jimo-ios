//
//  HomeMenu.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/3/21.
//

import SwiftUI

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
            
            
            NavigationLink(destination: EnterPhoneNumber(waitlistSignUp: true)) {
                LargeButton("Join Waitlist")
            }
            .padding(.bottom, 5)
            
            NavigationLink(destination: EnterPhoneNumber(waitlistSignUp: false)) {
                Text("Already have an invite? Sign in")
                    .font(Font.custom(Poppins.medium, size: 16))
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 50)
        .frame(maxHeight: .infinity)
        .onTapGesture {
            hideKeyboard()
        }
        .background(Color(.sRGB, red: 0.95, green: 0.95, blue: 0.95, opacity: 1).edgesIgnoringSafeArea(.all))
    }
}

struct HomeMenu_Previews: PreviewProvider {
    static var previews: some View {
        HomeMenu()
            .environmentObject(AppState(apiClient: APIClient()))
            .environment(\.font, Font.custom(Poppins.medium, size: 18))
    }
}
