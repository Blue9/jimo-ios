//
//  JimoApp.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI
import Firebase
import GoogleSignIn

@main
struct JimoApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    let apiClient = APIClient()
    
    @State var isPresented = true
    @State var image: UIImage? = nil
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppState(apiClient: apiClient))
                .preferredColorScheme(.light)
        }
    }
}

// Only for Google sign in (as of now)
class AppDelegate: NSObject, UIApplicationDelegate, GIDSignInDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        return true
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard let user = user else {
            return
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: user.authentication.idToken,
            accessToken: user.authentication.accessToken)
        Auth.auth().signIn(with: credential) { (result, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
        }
    }
}
