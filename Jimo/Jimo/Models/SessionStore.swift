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
    /// Handles auth state changes. Set by the app model. Do not overwrite.
    var handle: AuthStateDidChangeListenerHandle?
    
    /// The currently signed in Firebase user
    var currentUser: FirebaseAuth.User? {
        Auth.auth().currentUser
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
    
    private func unbind() {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    deinit {
        unbind()
    }
}
