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
    
    var currentUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }
    
    func listen() {
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if let user = user {
                withAnimation(.default, {
                    self.session = FirebaseUser(uid: user.uid, email: user.email)
                })
            }
            if (!self.initialized) {
                print("INitialized")
                self.initialized = true
            }
        })
    }
    
    func signUp(email: String, password: String, handler: @escaping AuthDataResultCallback) {
        Auth.auth().createUser(withEmail: email, password: password, completion: handler)
    }
    
    func signIn(email: String, password: String, handler: @escaping AuthDataResultCallback) {
        Auth.auth().signIn(withEmail: email, password: password, completion: handler)
    }
    
    func forgotPassword(email: String, handler: ((Error?) -> Void)?) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: handler)
    }
    
    func getAuthJWT(user: FirebaseAuth.User, handler: ((String?, Error?) -> Void)?) {
        user.getIDToken(completion: handler)
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Already logged out")
        }
        withAnimation(.default, {
            self.session = nil
        })
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
