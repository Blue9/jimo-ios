//
//  OldAuthView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/3/21.
//

import SwiftUI
import Combine
import FirebaseAuth
import GoogleSignIn

struct GoogleSignInButton: View {
    
    func signIn() {
        GIDSignIn.sharedInstance()?.presentingViewController = UIApplication.shared.windows.first?.rootViewController
        GIDSignIn.sharedInstance()?.signIn()
    }
    
    var body: some View {
        Button(action: self.signIn) {
            Text("Sign in with Google")
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(10)
        }
    }
}


struct SignUpView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var email = ""
    @State private var password = ""
    @State private var error = ""
    @State private var showError = false
    @State private var signUpCancellable: Cancellable? = nil
    
    func signUp() {
        hideKeyboard()
        signUpCancellable = appState.signUp(email: email, password: password)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    let code = (error as NSError).code
                    switch code {
                    case AuthErrorCode.invalidEmail.rawValue:
                        self.error = "Invalid email"
                        break
                    case AuthErrorCode.emailAlreadyInUse.rawValue:
                        self.error = "Email already in use"
                        break
                    default:
                        self.error = error.localizedDescription
                        break
                    }
                    showError = true
                }
            }, receiveValue: { result in
                self.email = ""
                self.password = ""
                self.error = ""
            })
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Image("logo")
                    .aspectRatio(contentMode: .fit)

                Text("Welcome to jimo!")
                TextField("Email", text: $email)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Colors.linearGradient, style: StrokeStyle(lineWidth: 2)))
                
                SecureField("Password", text: $password)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Colors.linearGradient, style: StrokeStyle(lineWidth: 2)))
                
                Button(action: signUp) {
                    Text("Sign up")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(Color("activity"))
                        .cornerRadius(10)
                }
                .shadow(radius: 5)

                GoogleSignInButton()
                    .shadow(radius: 5)

                NavigationLink(destination: SignInView()) {
                    Text("Already have an account?")
                }
            }
            .padding(.horizontal, 24)
        }
        .popup(isPresented: $showError, type: .toast, autohideIn: 2) {
            Toast(text: error, type: .error)
        }
        .navigationBarTitleDisplayMode(.inline)
        //.navigationTitle("Sign up")
        .toolbar {
            ToolbarItem(placement: .principal) {
                NavTitle("Sign up")
            }
        }
    }
}

struct SignInView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var email = ""
    @State private var password = ""
    @State private var error = ""
    @State private var showError = false
    @State private var showForgotPasswordSuccess = false
    @State private var signInCancellable: Cancellable? = nil
    @State private var forgotCancellable: Cancellable? = nil
    
    func setError(_ error: String) {
        showError = true
        self.error = error
    }
    
    func signIn() {
        hideKeyboard()
        signInCancellable = appState.signIn(email: email, password: password)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print("Error", error)
                    setError("Invalid email or password. Try again.")
                }
            }, receiveValue: { result in
                self.email = ""
                self.password = ""
                self.error = ""
            })
    }
    
    func forgotPassword() {
        hideKeyboard()
        forgotCancellable = appState.forgotPassword(email: email)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    setError(error.localizedDescription)
                }
            }, receiveValue: {
                self.email = ""
                self.password = ""
                showForgotPasswordSuccess = true
            })
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
                                    .stroke(Colors.linearGradient, style: StrokeStyle(lineWidth: 2)))
                
                SecureField("Password", text: $password)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Colors.linearGradient, style: StrokeStyle(lineWidth: 2)))
                
                Button(action: signIn) {
                    Text("Sign in")
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 50)
                        .foregroundColor(.white)
                        .background(Color("shopping"))
                        .cornerRadius(10)
                }
                .shadow(radius: 5)
                
                GoogleSignInButton()
                    .shadow(radius: 5)
                
                Button(action: forgotPassword) {
                    Text("Forgot password")
                        .cornerRadius(25)
                }
            }
            .padding(.horizontal, 24)
        }
        .popup(isPresented: $showError, type: .toast, autohideIn: 2) {
            Toast(text: error, type: .error)
        }
        .popup(isPresented: $showForgotPasswordSuccess, type: .toast, autohideIn: 2) {
            Toast(text: "Check your email for password recovery instructions", type: .success)
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
