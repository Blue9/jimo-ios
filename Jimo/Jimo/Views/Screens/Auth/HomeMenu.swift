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
    let height = UIScreen.main.bounds.height
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(maxHeight: height * 0.22)
            
            VStack(spacing: 0) {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 175)
                Text("Sign up to see recs\nfrom your friends.")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 16))
            }
            .scaledToFit()
            
            Spacer().frame(maxHeight: height * 0.23)
            
            VStack(spacing: 0) {
                NavigationLink(destination: EnterPhoneNumber()) {
                    Text("Sign Up")
                        .font(.system(size: 24))
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 60)
                        .foregroundColor(.white)
                        .background(Color(red: 25 / 255, green: 140 / 255, blue: 240 / 255))
                        .cornerRadius(10)
                }
                .padding(.bottom, 8)
                .buttonStyle(RaisedButtonStyle())
                
                HStack(spacing: 10) {
                    VStack {
                        Divider()
                            .frame(maxWidth: 100)
                            .background(Color.black)
                    }
                    Text("OR")
                        .font(.system(size: 16))
                    VStack {
                        Divider()
                            .frame(maxWidth: 100)
                            .background(Color.black)
                    }
                }
                .padding(.vertical, 5)
                
                NavigationLink(destination: EnterPhoneNumber()) {
                    Group {
                        Text("Already have an account? ") + Text("Sign in").bold()
                    }
                    .font(.system(size: 16))
                    .minimumScaleFactor(0.8)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .foregroundColor(.black)
                }
            }
            .padding(.bottom, 50)
            
            Spacer()
        }
        .padding(.horizontal, 50)
        .frame(maxHeight: .infinity)
        // This fixes a bug when moving back from EnterPhoneNumber with the keyboard open
        .edgesIgnoringSafeArea(.all)
        .background(Wave())
    }
}

struct HomeMenu_Previews: PreviewProvider {
    static var previews: some View {
        HomeMenu()
            .environmentObject(AppState(apiClient: APIClient()))
            .environmentObject(GlobalViewState())
            .environment(\.font, .system(size: 18))
    }
}
