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
    
    static func user(username: String) -> Endpoint {
        return Endpoint(path: "/users/\(username)")
    }
    
    static func feed(username: String) -> Endpoint {
        return Endpoint(path: "/users/\(username)/feed")
    }
    
    var url: URL? {
        var apiURL = URLComponents()
        apiURL.scheme = "http"
        apiURL.host = "localhost"
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
    @Published var sessionStore: SessionStore
    
    @Published var firebaseSession: FirebaseUser?
    @Published var currentUser: User? = nil
    
    @Published var loadingUserProfile: LoadUserResult? = nil
    @Published var initialized: Bool = false
    
    var anyCancellable: AnyCancellable? = nil
    
    init() {
        self.sessionStore = SessionStore()
        anyCancellable = self.sessionStore.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
    }
    
    func listen() {
        self.sessionStore.handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            withAnimation {
                if let user = user {
                    self.loadCurrentUserProfile()
                    self.firebaseSession = FirebaseUser(uid: user.uid, email: user.email)
                } else {
                    self.firebaseSession = nil
                }
                if (!self.initialized) {
                    print("Initialized")
                    self.initialized = true
                }
            }
        })
    }
    
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
    
    func buildRequest(url: URL, token: String, httpMethod: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = httpMethod
        return request
    }
    
    func doRequest<T: Codable>(endpoint: Endpoint, onComplete: @escaping (T?, RequestError?) -> Void) {
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
            let request = self.buildRequest(url: url, token: token)
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
    
    func signOut() {
        self.sessionStore.signOut()
        self.currentUser = nil
    }
    
    func getUser(username: String, onComplete: @escaping (User?, RequestError?) -> Void) {
        let endpoint = Endpoint.user(username: username)
        doRequest(endpoint: endpoint, onComplete: onComplete)
    }
    
    func getFeed(username: String, onComplete: @escaping ([Post]?, RequestError?) -> Void) {
        let endpoint = Endpoint.user(username: username)
        doRequest(endpoint: endpoint, onComplete: onComplete)
    }
}
