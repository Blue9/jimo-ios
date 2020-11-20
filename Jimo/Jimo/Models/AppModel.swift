//
//  App.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import Foundation


struct Endpoint {
    let path: String
    
    static func user(username: String) -> Endpoint {
        return Endpoint(path: "/users/\(username)")
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


class AppModel {
    func getUser(username: String, onComplete: @escaping (User?) -> Void) {
        let endpoint = Endpoint.user(username: username)
        guard let url = endpoint.url else {
            onComplete(nil)
            return
        }
        let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else {
                onComplete(nil)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            if let json = json {
                print(json.debugDescription)
                onComplete(User(json: json))
            } else {
                print("Could not retrieve json")
                onComplete(nil)
            }
        }

        task.resume()
    }

    func getFeed() -> [Post] {
        return []
    }
}
