//
//  App.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import SwiftUI
import Foundation
import Combine
import Firebase


struct Endpoint {
    let path: String
    
    static func me() -> Endpoint {
        return Endpoint(path: "/me")
    }
    
    static func createUser() -> Endpoint {
        return Endpoint(path: "/users/")
    }
    
    static func user(username: String) -> Endpoint {
        return Endpoint(path: "/users/\(username)")
    }
    
    static func feed(username: String) -> Endpoint {
        return Endpoint(path: "/users/\(username)/feed")
    }
    
    static func likePost(postId: String) -> Endpoint {
        return Endpoint(path: "/posts/\(postId)/likes")
    }
    
    var url: URL? {
        var apiURL = URLComponents()
        apiURL.scheme = "http"
        apiURL.host = "192.168.1.160"
        apiURL.port = 8000
        apiURL.path = path
        return apiURL.url
    }
}


enum RequestError: Error {
    case endpointError
    case tokenError
    case noResponse
    case decodeError
    case authError
    case notFound
    case unknownError
}

enum LoadUserResult {
    case success
    case loading
    case error
}


class AppModel: ObservableObject {
    /// Handles auth functionality
    @Published var sessionStore: SessionStore
    
    /// The current user (email and uid) if logged in to Firebase
    @Published var firebaseSession: FirebaseUser?
    
    /// The current user (full User object) if logged in and the profile exists and has been loaded
    @Published var currentUser: User? = nil
    
    /// Handles state when the user is logged in and we are loading the user profile
    @Published var loadingUserProfile: LoadUserResult? = nil
    
    /// If true, we have initialized Firebase auth
    @Published var initialized: Bool = false
    
    /// Used to allow sessionStore's published vars to propagate through to observers of self
    var anyCancellable: AnyCancellable? = nil
    
    /**
     Create a new AppModel object. This creates a SessionStore object as well.
     */
    init() {
        self.sessionStore = SessionStore()
        anyCancellable = self.sessionStore.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
    }
    
    /**
     Add a listener to Firebase auth changes. This should be called once, preferably after the view has rendered (e.g., in onAppear)
     */
    func listen() {
        self.sessionStore.handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            withAnimation {
                if let user = user {
                    self.loadCurrentUserProfile()
                    self.firebaseSession = FirebaseUser(uid: user.uid, email: user.email)
                } else {
                    self.firebaseSession = nil
                    self.currentUser = nil
                }
                if (!self.initialized) {
                    print("Initialized")
                    self.initialized = true
                }
            }
        })
    }
    
    /**
     Get an auth token for the logged in user if possible and pass it into makeRequest.
     
     If no token can be retrieved (i.e., an error occurs or the user is not authenticated), nil is passed to makeRequest.
     
     - Parameter makeRequest: The token handler.
     */
    func withToken(makeRequest: @escaping (String?) -> Void) {
        guard let currentUser = sessionStore.currentUser else {
            print("Not logged in")
            makeRequest(nil)
            return
        }
        sessionStore.getAuthJWT(user: currentUser) { (token, error) in
            if let error = error {
                print("Error when getting JWT", error.localizedDescription)
                makeRequest(nil)
                return
            }
            makeRequest(token)
        }
    }
    
    /**
     Build a URLRequest object given the url, auth token, and http method, which defaults to GET.
     
     - Parameter url: The request endpoint.
     - Parameter token: The Firebase auth token.
     - Parameter httpMethod: The http method. Defaults to GET.
     
     - Returns: The URLRequest object.
     */
    func buildRequest(url: URL, token: String, httpMethod: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = httpMethod
        return request
    }
    
    /**
     Make a GET request to the given endpoinrt and pass the result to the given handler.
     
     - Parameter endpoint: The endpoint.
     - Parameter onComplete: The result handler. Exactly one of the two parameters will be non-nil.
     */
    func doRequest<T: Codable>(endpoint: Endpoint, httpMethod: String = "GET", body: Codable? = nil, onComplete: @escaping (T?, RequestError?) -> Void) {
        guard let url = endpoint.url else {
            onComplete(nil, RequestError.endpointError)
            return
        }
        withToken { token in
            guard let token = token else {
                print("Could not retrieve token")
                onComplete(nil, RequestError.tokenError)
                return
            }
            let request = self.buildRequest(url: url, token: token, httpMethod: httpMethod)
            URLSession.shared.dataTask(with: request) {(data, response, error) in
                guard let response = response as? HTTPURLResponse else {
                    print("Did not get response from server")
                    onComplete(nil, RequestError.noResponse)
                    return
                }
                if response.statusCode >= 300 || response.statusCode < 200 {
                    switch response.statusCode {
                    case 401, 403:
                        onComplete(nil, RequestError.authError)
                    case 404:
                        onComplete(nil, RequestError.notFound)
                    default:
                        onComplete(nil, RequestError.unknownError)
                    }
                    return
                }
                guard let data = data else {
                    print("Did not get any data for", url.relativeString)
                    onComplete(nil, RequestError.noResponse)
                    return
                }
                let decoded: T? = try? JSONDecoder().decode(T.self, from: data)
                onComplete(decoded, decoded == nil ? RequestError.decodeError : nil)
            }.resume()
        }
    }
    
    /**
     After logging into Firebase, attempt to initialize the current user profile.
     
     self.loadingUserProfile tracks that status of loading the profile. This should only be called once per session,
     right after the Firebase user has been initialized.
     */
    func loadCurrentUserProfile() {
        withAnimation {
            if self.currentUser != nil {
                self.loadingUserProfile = .success
                return
            }
            self.loadingUserProfile = .loading
        }
        let endpoint = Endpoint.me()
        doRequest(endpoint: endpoint, onComplete: { (user: User?, error: RequestError?) -> Void in
            // Artificial delay makes everything look nicer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    self.currentUser = user
                    if let error = error, error != RequestError.notFound {
                        // error when requesting
                        self.loadingUserProfile = .error
                    } else {
                        self.loadingUserProfile = .success
                    }
                }
            }
        })
    }
    
    /**
     Sign the current user out. Does nothing if the user was already signed out.
     */
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Already logged out")
        }
        self.currentUser = nil
    }
    
    /**
     Get the user with the given username and pass the result into the given handler.
     */
    func createUser(_ request: CreateUserRequest, onComplete: @escaping (CreateUserResponse?, RequestError?) -> Void) {
        let endpoint = Endpoint.createUser()
        doRequest(endpoint: endpoint, onComplete: onComplete)
    }
    
    /**
     Get the user with the given username and pass the result into the given handler.
     */
    func getUser(username: String, onComplete: @escaping (User?, RequestError?) -> Void) {
        let endpoint = Endpoint.user(username: username)
        doRequest(endpoint: endpoint, onComplete: onComplete)
    }
    
    /**
     Get the feed for the current user and pass the result into the given handler.
     */
    func getFeed(onComplete: @escaping ([Post]?, RequestError?) -> Void) {
        guard let user = currentUser else {
            onComplete(nil, RequestError.authError)
            return
        }
        let endpoint = Endpoint.feed(username: user.username)
        doRequest(endpoint: endpoint, onComplete: onComplete)
    }
}
