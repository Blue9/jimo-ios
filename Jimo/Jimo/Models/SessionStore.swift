//
//  SessionStore.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/24/20.
//

import SwiftUI
import Foundation
import Firebase
import Combine


// From https://www.youtube.com/watch?v=FhLEwqyVSjE
class SessionStore: ObservableObject {
    @Published var session: FirebaseUser?
    @Published var initialized = false
    var handle: AuthStateDidChangeListenerHandle?
    
    func listen() {
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            print("handler called")
            if let user = user {
                print("setting session")
                withAnimation(.default, {
                    self.session = FirebaseUser(uid: user.uid, email: user.email)
                })
            }
            if (!self.initialized) {
                self.initialized = true
            }
        })
    }
    
    func signUp(email: String, password: String, handler: @escaping AuthDataResultCallback) {
        Auth.auth().createUser(withEmail: email, password: password, completion: handler)
    }
    
    func signIn(email: String, password: String, handler: @escaping AuthDataResultCallback) {
        print("Sign in called")
        Auth.auth().signIn(withEmail: email, password: password, completion: handler)
    }
    
    func forgotPassword(email: String, handler: ((Error?) -> Void)?) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: handler)
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            withAnimation(.default, {
                self.session = nil
            })
        } catch {
            print("Already logged out")
        }
    }
    
    func unbind() {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    deinit {
        unbind()
    }
}
