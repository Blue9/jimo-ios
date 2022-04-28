//
//  EmailLogin.swift
//  Jimo
//
//  Created by Kevin Nizza on 4/28/22.
//

import SwiftUI
import Combine

struct EmailLogin: View {
    @EnvironmentObject var appState: AppState
    
    @State private var email = ""
    @State private var password = ""
    @State private var error = ""
    @State private var showError = false
    @State private var signInCancellable: Cancellable? = nil
    
    func setError(_ error: String) {
        showError = true
        self.error = error
    }
    
    func signIn() {
        hideKeyboard()
    }
        
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Image("logo")
                    .aspectRatio(contentMode: .fit)
                
                Text("Welcome back!")
                TextField("Email", text: $email)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("foreground")))
                
                SecureField("Password", text: $password)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color("foreground")))
                
                Button(action: signIn) {
                    Text("Sign in")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(Color("shopping"))
                        .cornerRadius(10)
                }
                .shadow(radius: 5)
                
                
            }
            .padding(.horizontal, 24)
        }
        .popup(isPresented: $showError, type: .toast, autohideIn: 2) {
            Toast(text: error, type: .error)
        }
        .navigationBarTitleDisplayMode(.inline)
        //.navigationTitle("Sign in")
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavTitle("Sign in")
            }
        }
    }
}
