//
//  AuthView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/25/20.
//

import SwiftUI
import Firebase
import GoogleSignIn

struct GoogleSignInButton: View {
    var body: some View {
        Button(action: {
            GIDSignIn.sharedInstance()?.presentingViewController = UIApplication.shared.windows.first?.rootViewController
            GIDSignIn.sharedInstance()?.signIn()
        }) {
            Text("Sign in with Google")
                .frame(minWidth: 0, maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(.white)
                .background(Color.blue)
                .cornerRadius(25)
        }
    }
}

struct SignUpView: View {
    @State var email = ""
    @State var password = ""
    @State var error = " "
    
    @EnvironmentObject var session: SessionStore
    
    func signUp() {
        session.signUp(email: email, password: password, handler: { (result, error) in
            if let error = error {
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
            } else {
                self.email = ""
                self.password = ""
                self.error = " "
            }
        })
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to jimō :^)")
            TextField("Email", text: $email)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 25)
                                .stroke(style: StrokeStyle(lineWidth: 4))
                                .foregroundColor(.blue))
            
            SecureField("Password", text: $password)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 25)
                                .stroke(style: StrokeStyle(lineWidth: 4))
                                .foregroundColor(.blue))
            
            Button(action: signUp) {
                Text("Sign up")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(.white)
                    .background(LinearGradient(gradient: Gradient(colors: [.blue, .green]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(25)
            }
            
            GoogleSignInButton()
            
            NavigationLink(destination: SignInView()) {
                Text("Already have an account?")
            }
            
            Text(error)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 48)
        .navigationBarTitle("Sign up", displayMode: .inline)
    }
}

struct SignInView: View {
    @State var email = ""
    @State var password = ""
    @State var error = " "
    
    @EnvironmentObject var session: SessionStore
    
    func signIn() {
        session.signIn(email: email, password: password, handler: { (result, error) in
            if error != nil {
                self.error = "Invalid email or password. Try again."
            } else {
                self.email = ""
                self.password = ""
                self.error = " "
            }
        })
    }

    func forgotPassword() {
        session.forgotPassword(email: email, handler: { error in
            print(error?.localizedDescription ?? "guh")
            if let error = error {
                self.error = error.localizedDescription
            } else {
                self.email = ""
                self.password = ""
                self.error = "Check your email for password recovery instructions"
            }
        })
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome back :^)")
            TextField("Email", text: $email)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 25)
                                .stroke(style: StrokeStyle(lineWidth: 4))
                                .foregroundColor(.blue))
            
            SecureField("Password", text: $password)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 25)
                                .stroke(style: StrokeStyle(lineWidth: 4))
                                .foregroundColor(.blue))
            
            Button(action: signIn) {
                Text("Sign in")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .frame(height: 50)
                    .foregroundColor(.white)
                    .background(LinearGradient(gradient: Gradient(colors: [.blue, .green]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(25)
            }
            
            GoogleSignInButton()
            
            Button(action: forgotPassword) {
                Text("Forgot password")
                    .cornerRadius(25)
            }
            
            Text(error)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 48)
        .navigationBarTitle("Sign in", displayMode: .inline)
    }
}

struct AuthView: View {
    var body: some View {
        NavigationView {
            SignUpView()
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView().environmentObject(SessionStore())
    }
}
