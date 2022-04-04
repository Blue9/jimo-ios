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
    @Environment(\.colorScheme) var colorScheme
    
    let height = UIScreen.main.bounds.height
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(maxHeight: height * 0.22)
            
            VStack(spacing: 0) {
                Image("logo")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(Color("foreground"))
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
                    LargeButton("Sign Up")
                }
                .padding(.bottom, 8)
                .buttonStyle(RaisedButtonStyle())
                
                HStack(spacing: 10) {
                    VStack {
                        Divider()
                            .frame(maxWidth: 100)
                            .background(Color("foreground"))
                    }
                    Text("OR")
                        .font(.system(size: 16))
                        .foregroundColor(Color("foreground"))
                    VStack {
                        Divider()
                            .frame(maxWidth: 100)
                            .background(Color("foreground"))
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
                    .foregroundColor(Color("foreground"))
                }
            }
            .padding(.bottom, 50)
            
            Spacer()
        }
        .padding(.horizontal, 50)
        .frame(maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        .trackScreen(.landing)
    }
}