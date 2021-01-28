//
//  APIClient.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/11/21.
//

import SwiftUI
import Foundation
import Combine
import MapKit
import Firebase


struct Endpoint {
    let path: String
    var queryItems: [URLQueryItem] = []
    
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
    
    static func posts(username: String) -> Endpoint {
        return Endpoint(path: "/users/\(username)/posts")
    }
    
    static func createPost() -> Endpoint {
        return Endpoint(path: "/posts/")
    }
    
    static func postLikes(postId: String) -> Endpoint {
        return Endpoint(path: "/posts/\(postId)/likes")
    }
    
    static func getMap(centerLat: Double, centerLong: Double, spanLat: Double, spanLong: Double) -> Endpoint {
        return Endpoint(
            path: "/places/map",
            queryItems: [
                URLQueryItem(name: "center_lat", value: String(centerLat)),
                URLQueryItem(name: "center_long", value: String(centerLong)),
                URLQueryItem(name: "span_lat", value: String(spanLat)),
                URLQueryItem(name: "span_long", value: String(spanLong))
            ])
    }
    
    var url: URL? {
        var apiURL = URLComponents()
        apiURL.scheme = "http"
        apiURL.host = "192.168.1.160"
        apiURL.port = 8000
        apiURL.path = path
        apiURL.queryItems = queryItems
        return apiURL.url
    }
}


enum APIError: Error {
    case endpointError
    case tokenError
    case noResponse
    case encodeError
    case decodeError
    case authError
    case notFound
    case serverError
    case unknownError
}

struct EmptyBody: Encodable {
}

class APIClient: ObservableObject {
    var authClient: AuthClient
    
    /**
     Create a new API client. This creates the auth client as well.
     */
    init() {
        self.authClient = .init()
    }
    
    /**
     Listen to Firebase auth changes.
     */
    func setAuthHandler(handle: @escaping (Firebase.Auth, Firebase.User?) -> Void) {
        self.authClient.handle = Auth.auth().addStateDidChangeListener(handle)
    }
    
    /**
     Get the current user profile.
     */
    func getMe() -> AnyPublisher<PublicUser, APIError> {
        return doRequest(endpoint: Endpoint.me())
    }
    
    /**
     Create a new user profile.
     */
    func createUser(_ request: CreateUserRequest) -> AnyPublisher<CreateUserResponse, APIError> {
        return doRequest(endpoint: Endpoint.createUser(), httpMethod: "POST", body: request)
    }
    
    /**
     Get the user with the given username and pass the result into the given handler.
     */
    func getUser(username: String) -> AnyPublisher<PublicUser, APIError> {
        return doRequest(endpoint: Endpoint.user(username: username))
    }
    
    /**
     Get the feed for the given user.
     */
    func getFeed(username: String) -> AnyPublisher<[Post], APIError> {
        return doRequest(endpoint: Endpoint.feed(username: username))
    }
    
    /**
     Get the map for the given user.
     */
    func getMap(region: MKCoordinateRegion) -> AnyPublisher<[Post], APIError> {
        return doRequest(endpoint: Endpoint.getMap(
                            centerLat: region.center.latitude,
                            centerLong: region.center.longitude,
                            spanLat: region.span.latitudeDelta,
                            spanLong: region.span.longitudeDelta))
    }
    
    /**
     Get the posts by the given user.
     */
    func getPosts(username: String) -> AnyPublisher<[Post], APIError> {
        doRequest(endpoint: Endpoint.posts(username: username))
    }
    
    /**
     Create a new post.
     */
    func createPost(_ request: CreatePostRequest) -> AnyPublisher<Post, APIError> {
        return doRequest(endpoint: Endpoint.createPost(), httpMethod: "POST", body: request)
    }
    
    /**
     Like the given post.
     */
    func likePost(postId: PostId) -> AnyPublisher<LikePostResponse, APIError> {
        doRequest(endpoint: Endpoint.postLikes(postId: postId), httpMethod: "POST")
    }
    
    /**
     Unlike the given post.
     */
    func unlikePost(postId: PostId) -> AnyPublisher<LikePostResponse, APIError> {
        doRequest(endpoint: Endpoint.postLikes(postId: postId), httpMethod: "DELETE")
    }
    
    /**
     Get an auth token for the logged in user if possible.
     */
    private func getToken() -> AnyPublisher<String, APIError> {
        guard let currentUser = authClient.currentUser else {
            print("Not logged in")
            return Fail(error: APIError.authError)
                .eraseToAnyPublisher()
        }
        return authClient.getAuthJWT(user: currentUser)
            .mapError({ _ in APIError.tokenError })
            .eraseToAnyPublisher()
    }
    
    /**
     Build a URLRequest object given the url, auth token, and http method, which defaults to GET.
     
     - Parameter url: The request endpoint.
     - Parameter token: The Firebase auth token.
     - Parameter httpMethod: The http method. Defaults to GET.
     - Parameter body: JSON body of request.
     
     - Returns: The URLRequest object.
     */
    private func buildRequest(url: URL, token: String, httpMethod: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpMethod = httpMethod
        request.httpBody = body
        return request
    }
    
    /**
     Make a request to the given endpoinrt and pass the result to the given handler.
     
     - Parameter endpoint: The endpoint.
     */
    private func doRequest<Response: Decodable>(endpoint: Endpoint, httpMethod: String = "GET") -> AnyPublisher<Response, APIError> {
        return doRequest(endpoint: endpoint, httpMethod: httpMethod, body: nil as EmptyBody?)
    }
    
    /**
     Make a request to the given endpoinrt and pass the result to the given handler.
     
     - Parameter endpoint: The endpoint.
     */
    private func doRequest<Request: Encodable, Response: Decodable>(endpoint: Endpoint,
                                                          httpMethod: String = "GET",
                                                          body: Request? = nil) -> AnyPublisher<Response, APIError> {
        
        guard let url = endpoint.url else {
            return Fail(error: APIError.endpointError)
                .eraseToAnyPublisher()
        }
        var jsonBody: Data? = nil
        if let body = body {
            jsonBody = try? JSONEncoder().encode(body)
            if jsonBody == nil {
                return Fail(error: APIError.encodeError)
                    .eraseToAnyPublisher()
            }
        }
        return getToken()
            .map { token in self.buildRequest(url: url, token: token, httpMethod: httpMethod, body: jsonBody) }
            .flatMap { request -> AnyPublisher<Response, APIError> in
                URLSession.shared.dataTaskPublisher(for: request)
                    .tryMap(self.urlSessionPublisherHandler)
                    .mapError({ $0 as? APIError ?? APIError.unknownError })
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private func urlSessionPublisherHandler<Response: Decodable>(result: URLSession.DataTaskPublisher.Output) throws -> Response {
        guard let response = result.response as? HTTPURLResponse else {
            print("Did not get response from server")
            throw APIError.noResponse
        }
        if response.statusCode >= 300 || response.statusCode < 200 {
            switch response.statusCode {
            case 401, 403:
                throw APIError.authError
            case 404:
                throw APIError.notFound
            case 500...:
                throw APIError.serverError
            default:
                throw APIError.unknownError
            }
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(Response.self, from: result.data)
        } catch DecodingError.keyNotFound(let key, let context) {
            Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(let context) {
            Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
        } catch let error as NSError {
            NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
        }
        throw APIError.decodeError
//        if let decoded = try? decoder.decode(Response.self, from: result.data) {
//            return decoded
//        } else {
//            throw APIError.decodeError
//        }
    }
}

