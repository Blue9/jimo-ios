//
//  App.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import Foundation
import Combine


struct Endpoint {
    let path: String
    
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


class AppModel: ObservableObject {
    @Published var sessionStore: SessionStore
    
    var anyCancellable: AnyCancellable? = nil
    
    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
        anyCancellable = self.sessionStore.objectWillChange.sink { [weak self] (_) in
            self?.objectWillChange.send()
        }
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
    
    func doRequest<T: Codable>(endpoint: Endpoint, onComplete: @escaping (T?) -> Void) {
        guard let url = endpoint.url else {
            onComplete(nil)
            return
        }
        withToken { token in
            guard let token = token else {
                print("Could not retrieve token")
                onComplete(nil)
                return
            }
            let request = self.buildRequest(url: url, token: token)
            URLSession.shared.dataTask(with: request) {(data, response, error) in
                guard let data = data else {
                    print("Could not get response for", url.relativeString)
                    onComplete(nil)
                    return
                }
                let response: T? = try! JSONDecoder().decode(T.self, from: data)
                print(response.debugDescription)
                onComplete(response)
            }.resume()
        }
    }
    
    func getUser(username: String, onComplete: @escaping (User?) -> Void) {
        let endpoint = Endpoint.user(username: username)
        doRequest(endpoint: endpoint, onComplete: onComplete)
    }
    
    func getFeed(username: String, onComplete: @escaping ([Post]?) -> Void) {
        let endpoint = Endpoint.user(username: username)
        doRequest(endpoint: endpoint, onComplete: onComplete)
    }
}
