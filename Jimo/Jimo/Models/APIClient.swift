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
    
    var url: URL? {
        var apiURL = URLComponents()
        apiURL.scheme = "https"
        apiURL.host = "api.jimoapp.com"
        apiURL.port = 443
        apiURL.path = path
        apiURL.queryItems = queryItems
        return apiURL.url
    }
    
    // MARK: - Invite + waitlist endpoints
    
    static func waitlistStatus() -> Endpoint {
        return Endpoint(path: "/waitlist/status")
    }
    
    static func joinWaitlist() -> Endpoint {
        return Endpoint(path: "/waitlist")
    }
    
    static func inviteUser() -> Endpoint {
        return Endpoint(path: "/waitlist/invites")
    }
    
    // MARK: - Onboarding endpoints
    
    static func contacts() -> Endpoint {
        return Endpoint(path: "/me/contacts")
    }
    
    static func featuredUsers() -> Endpoint {
        return Endpoint(path: "/me/suggested")
    }
    
    static func suggestedUsers() -> Endpoint {
        return Endpoint(path: "/me/suggested-users")
    }
    
    static func followMany() -> Endpoint {
        return Endpoint(path: "/me/following")
    }
    
    // MARK: - User endpoints
    
    static func me() -> Endpoint {
        return Endpoint(path: "/me")
    }
    
    static func savedPosts(cursor: String? = nil) -> Endpoint {
        let path = "/me/saved-posts"
        var queryItems: [URLQueryItem] = []
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        return Endpoint(path: path, queryItems: queryItems)
    }
    
    static func profilePicture() -> Endpoint {
        return Endpoint(path: "/me/photo")
    }
    
    static func createUser() -> Endpoint {
        return Endpoint(path: "/users")
    }
    
    static func user(username: String) -> Endpoint {
        return Endpoint(path: "/users/\(username)")
    }
    
    static func preferences() -> Endpoint {
        return Endpoint(path: "/me/preferences")
    }
    
    static func feed(cursor: String? = nil) -> Endpoint {
        let path = "/me/feed"
        if let cursor = cursor {
            return Endpoint(path: path, queryItems: [URLQueryItem(name: "cursor", value: cursor)])
        }
        return Endpoint(path: path)
    }
    
    static func posts(username: String, cursor: String? = nil, limit: Int? = nil) -> Endpoint {
        let path = "/users/\(username)/posts"
        var queryItems: [URLQueryItem] = []
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        return Endpoint(path: path, queryItems: queryItems)
    }
    
    static func followers(username: String, cursor: String? = nil) -> Endpoint {
        let queryItems = [URLQueryItem(name: "cursor", value: cursor)]
        return Endpoint(path: "/users/\(username)/followers", queryItems: cursor != nil ? queryItems : [])
    }
    
    static func following(username: String, cursor: String? = nil) -> Endpoint {
        let queryItems = [URLQueryItem(name: "cursor", value: cursor)]
        return Endpoint(path: "/users/\(username)/following", queryItems: cursor != nil ? queryItems : [])
    }
    
    // MARK: - Relation endpoints
    
    static func follow(username: String) -> Endpoint {
        return Endpoint(path: "/users/\(username)/follow")
    }
    
    static func unfollow(username: String) -> Endpoint {
        return Endpoint(path: "/users/\(username)/unfollow")
    }
    
    static func block(username: String) -> Endpoint {
        return Endpoint(path: "/users/\(username)/block")
    }
    
    static func unblock(username: String) -> Endpoint {
        return Endpoint(path: "/users/\(username)/unblock")
    }
    
    static func relation(username: String) -> Endpoint {
        return Endpoint(path: "/users/\(username)/relation")
    }
    
    // MARK: - Post endpoints
    
    static func createPost() -> Endpoint {
        return Endpoint(path: "/posts")
    }
    
    static func post(postId: PostId) -> Endpoint {
        return Endpoint(path: "/posts/\(postId)")
    }
    
    static func reportPost(postId: PostId) -> Endpoint {
        return Endpoint(path: "/posts/\(postId)/report")
    }
    
    static func postLikes(postId: String) -> Endpoint {
        return Endpoint(path: "/posts/\(postId)/likes")
    }
    
    static func savePost(postId: String) -> Endpoint {
        return Endpoint(path: "/posts/\(postId)/save")
    }
    
    static func unsavePost(postId: String) -> Endpoint {
        return Endpoint(path: "/posts/\(postId)/unsave")
    }
    
    // MARK: - Comment endpoints
    
    static func comments(for postId: PostId, cursor: String? = nil) -> Endpoint {
        let path = "/posts/\(postId)/comments"
        if let cursor = cursor {
            return Endpoint(path: path, queryItems: [URLQueryItem(name: "cursor", value: cursor)])
        }
        return Endpoint(path: path)
    }
    
    static func createComment() -> Endpoint {
        return Endpoint(path: "/comments")
    }
    
    static func comment(commentId: CommentId) -> Endpoint {
        return Endpoint(path: "/comments/\(commentId)")
    }
    
    static func commentLikes(commentId: CommentId) -> Endpoint {
        return Endpoint(path: "/comments/\(commentId)/likes")
    }
    
    // MARK: - Search endpoints
    
    static func searchUser(query: String) -> Endpoint {
        return Endpoint(path: "/search/users", queryItems: [URLQueryItem(name: "q", value: query)])
    }
    
    // MARK: - Discover endpoint
    
    static func discoverFeed() -> Endpoint {
        return Endpoint(path: "/me/discover")
    }
    
    // MARK: - Map endpoints
    
    @available(*, deprecated, message: "Use getGlobalMap, getFollowingMap, or getCustomMap")
    static func getMap() -> Endpoint {
        return Endpoint(path: "/me/map")
    }
    
    @available(*, deprecated, message: "Use getGlobalMap, getFollowingMap, or getCustomMap")
    static func getMapV2() -> Endpoint {
        return Endpoint(path: "/me/mapV2")
    }
    
    static func getGlobalMap() -> Endpoint {
        return Endpoint(path: "/map/global")
    }
    
    static func getFollowingMap() -> Endpoint {
        return Endpoint(path: "/map/following")
    }

    static func getSavedPostsMap() -> Endpoint {
        return Endpoint(path: "/map/saved-posts")
    }
    
    static func getCustomMap() -> Endpoint {
        return Endpoint(path: "/map/custom")
    }
    
    static func getPlaceIcon(placeId: PlaceId) -> Endpoint {
        return Endpoint(path: "/places/\(placeId)/icon")
    }
    
    static func getMutualPosts(placeId: PlaceId) -> Endpoint {
        return Endpoint(path: "/places/\(placeId)/mutualPosts")
    }
    
    static func getGlobalMutualPostsV3(placeId: PlaceId) -> Endpoint {
        return Endpoint(path: "/places/\(placeId)/getMutualPostsV3/global")
    }
    
    static func getFollowingMutualPostsV3(placeId: PlaceId) -> Endpoint {
        return Endpoint(path: "/places/\(placeId)/getMutualPostsV3/following")
    }
    
    static func getSavedPostsMapMutualPostsV3(placeId: PlaceId) -> Endpoint {
        return Endpoint(path: "/places/\(placeId)/getMutualPostsV3/saved-posts")
    }
    
    static func getCustomMutualPostsV3(placeId: PlaceId) -> Endpoint {
        return Endpoint(path: "/places/\(placeId)/getMutualPostsV3/custom")
    }
    
    // MARK: Feedback endpoint
    
    static func submitFeedback() -> Endpoint {
        return Endpoint(path: "/feedback")
    }
    
    static func notificationToken() -> Endpoint {
        return Endpoint(path: "/notifications/token")
    }
    
    static func getNotificationsFeed(token: String?) -> Endpoint {
        let queryItems = [URLQueryItem(name: "cursor", value: token)]
        return Endpoint(path: "/notifications/feed", queryItems: token != nil ? queryItems : [])
    }
    
    static func uploadImage() -> Endpoint {
        return Endpoint(path: "/images")
    }
}


enum APIError: Error, Equatable {
    case requestError([String: String]?)
    case endpointError
    case tokenError
    case noResponse
    case encodeError
    case decodeError
    case authError
    case notFound
    case methodNotAllowed
    case rateLimitError
    case serverError
    case unknownError
    
    var message: String? {
        if case let .requestError(maybeErrors) = self,
           let errors = maybeErrors,
           let first = errors.first {
            return first.value
        }
        return nil
    }
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
    
    // MARK: - Invite + waitlist endpoints
    
    /**
     Check if the current user is on the waitlist.
     */
    func getWaitlistStatus() -> AnyPublisher<UserWaitlistStatus, APIError> {
        return doRequest(endpoint: Endpoint.waitlistStatus())
    }
    
    /**
     Add the current user to the waitlist.
     */
    func joinWaitlist() -> AnyPublisher<UserWaitlistStatus, APIError> {
        return doRequest(endpoint: Endpoint.joinWaitlist(), httpMethod: "POST")
    }
    
    /**
     Invite another user.
     */
    func inviteUser(phoneNumber: String) -> AnyPublisher<UserInviteStatus, APIError> {
        return doRequest(endpoint: Endpoint.inviteUser(),
                         httpMethod: "POST",
                         body: InviteUserRequest(phoneNumber: phoneNumber))
    }
    
    // MARK: - Onboarding endpoints
    
    /**
     Get users with any of the given phone numbers.
     */
    func getUsersInContacts(phoneNumbers: [String]) -> AnyPublisher<[PublicUser], APIError> {
        return doRequest(endpoint: Endpoint.contacts(),
                         httpMethod: "POST",
                         body: PhoneNumbersRequest(phoneNumbers: phoneNumbers))
    }
    
    /**
     Get the list of featured users.
     */
    func getFeaturedUsers() -> AnyPublisher<[PublicUser], APIError> {
        return doRequest(endpoint: Endpoint.featuredUsers())
    }
    
    /**
     Get the list of suggested users.
     */
    func getSuggestedUsers() -> AnyPublisher<[PublicUser], APIError> {
        return doRequest(endpoint: Endpoint.suggestedUsers())
    }
    
    /**
     Follow the list of usernames.
     */
    func followMany(usernames: [String]) -> AnyPublisher<SimpleResponse, APIError> {
        return doRequest(endpoint: Endpoint.followMany(),
                         httpMethod: "POST",
                         body: FollowManyRequest(usernames: usernames))
    }
    
    // MARK: - Notification endpoints
    
    /**
     Register the notification token.
     */
    func registerNotificationToken(token: String) -> AnyPublisher<SimpleResponse, APIError> {
        return doRequest(endpoint: Endpoint.notificationToken(),
                         httpMethod: "POST",
                         body: NotificationTokenRequest(token: token))
    }
    
    /**
     Remove the notification token.
     */
    func removeNotificationToken(token: String) -> AnyPublisher<SimpleResponse, APIError> {
        return doRequest(endpoint: Endpoint.notificationToken(),
                         httpMethod: "DELETE",
                         body: NotificationTokenRequest(token: token))
    }
    
    /**
     Get the notification feed.
     */
    func getNotificationsFeed(token: String?) -> AnyPublisher<NotificationFeedResponse, APIError> {
        return doRequest(endpoint: Endpoint.getNotificationsFeed(token: token))
    }
    
    // MARK: - User endpoints
    
    /**
     Get the current user profile.
     */
    func getMe() -> AnyPublisher<PublicUser, APIError> {
        return doRequest(endpoint: Endpoint.me())
    }
    
    /**
     Get the saved posts by the current user.
     */
    func getSavedPosts(cursor: String? = nil) -> AnyPublisher<FeedResponse, APIError> {
        doRequest(endpoint: Endpoint.savedPosts(cursor: cursor))
    }
    
    /**
     Create a new user profile.
     */
    func createUser(_ request: CreateUserRequest) -> AnyPublisher<CreateUserResponse, APIError> {
        return doRequest(endpoint: Endpoint.createUser(), httpMethod: "POST", body: request)
    }
    
    /**
     Update the given user's profile.
     */
    func updateProfile(_ request: UpdateProfileRequest) -> AnyPublisher<UpdateProfileResponse, APIError> {
        return doRequest(endpoint: Endpoint.me(), httpMethod: "POST", body: request)
    }
    
    /**
     Set the current user's profile picture.
     */
    func uploadProfilePicture(imageData: Data) -> AnyPublisher<PublicUser, APIError> {
        guard let url = Endpoint.profilePicture().url else {
            return Fail(error: APIError.endpointError).eraseToAnyPublisher()
        }
        return getToken()
            .flatMap { token in
                ImageUploadService.uploadImage(url: url, imageData: imageData, token: token)
                    .tryMap(self.urlSessionPublisherHandler)
                    .mapError { $0 as? APIError ?? APIError.unknownError }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /**
     Get the given user's preferences.
     */
    func getPreferences() -> AnyPublisher<UserPreferences, APIError> {
        return doRequest(endpoint: Endpoint.preferences())
    }
    
    /**
     Update the given user's preferences.
     */
    func updatePreferences(_ request: UserPreferences) -> AnyPublisher<UserPreferences, APIError> {
        return doRequest(endpoint: Endpoint.preferences(), httpMethod: "POST", body: request)
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
    func getFeed(cursor: String? = nil) -> AnyPublisher<FeedResponse, APIError> {
        return doRequest(endpoint: Endpoint.feed(cursor: cursor))
    }
    
    /**
     Get the map for the given user.
     */
    @available(*, deprecated, message: "Use getGlobalMap, getFollowingMap, or getCustomMap")
    func getMap() -> AnyPublisher<[MapPlace], APIError> {
        return doRequest(endpoint: Endpoint.getMap())
    }
    
    /**
     Get the map for the given user.
     */
    @available(*, deprecated, message: "Use getGlobalMap, getFollowingMap, or getCustomMap")
    func getMapV2() -> AnyPublisher<MapResponse, APIError> {
        return doRequest(endpoint: Endpoint.getMapV2())
    }
    
    /**
     Get the global map.
     */
    func getGlobalMap(region: Region, categories: [String]) -> AnyPublisher<MapResponseV3, APIError> {
        return doRequest(
            endpoint: Endpoint.getGlobalMap(),
            httpMethod: "POST",
            body: GetMapRequest(region: region, categories: categories)
        )
    }
    
    /**
     Get the map of the current user's following list.
     */
    func getFollowingMap(region: Region, categories: [String]) -> AnyPublisher<MapResponseV3, APIError> {
        return doRequest(
            endpoint: Endpoint.getFollowingMap(),
            httpMethod: "POST",
            body: GetMapRequest(region: region, categories: categories)
        )
    }
    
    /**
     Get the map of the current user's saved posts.
     */
    func getSavedPostsMap(region: Region, categories: [String]) -> AnyPublisher<MapResponseV3, APIError> {
        return doRequest(
            endpoint: Endpoint.getSavedPostsMap(),
            httpMethod: "POST",
            body: GetMapRequest(region: region, categories: categories)
        )
    }
    
    /**
     Get the map of the given users.
     */
    func getCustomMap(region: Region, userIds: [String], categories: [String]) -> AnyPublisher<MapResponseV3, APIError> {
        return doRequest(
            endpoint: Endpoint.getCustomMap(),
            httpMethod: "POST",
            body: CustomMapRequest(region: region, categories: categories, users: userIds)
        )
    }
    
    // MARK: - Get mutual posts
    
    /**
     Get the mutual posts for the given place
     */
    @available(*, deprecated, message: "Use V3 endpoint")
    func getMutualPosts(for placeId: PlaceId) -> AnyPublisher<[Post], APIError> {
        return doRequest(endpoint: Endpoint.getMutualPosts(placeId: placeId))
    }
    
    /**
     Get all posts for the given place
     */
    func getGlobalMutualPostsV3(for placeId: PlaceId, categories: [String]) -> AnyPublisher<[Post], APIError> {
        return doRequest(
            endpoint: Endpoint.getGlobalMutualPostsV3(placeId: placeId),
            httpMethod: "POST",
            body: PlaceLoadRequest(categories: categories)
        )
    }
    
    /**
     Get friends' posts for the given place
     */
    func getFollowingMutualPostsV3(for placeId: PlaceId, categories: [String]) -> AnyPublisher<[Post], APIError> {
        return doRequest(
            endpoint: Endpoint.getFollowingMutualPostsV3(placeId: placeId),
            httpMethod: "POST",
            body: PlaceLoadRequest(categories: categories)
        )
    }
    
    /**
     Get all saved posts for the given place
     */
    func getSavedPostsMapMutualPostsV3(for placeId: PlaceId, categories: [String]) -> AnyPublisher<[Post], APIError> {
        return doRequest(
            endpoint: Endpoint.getSavedPostsMapMutualPostsV3(placeId: placeId),
            httpMethod: "POST",
            body: PlaceLoadRequest(categories: categories)
        )
    }
    
    /**
     Get the posts for the given place and list of users
     */
    func getCustomMutualPostsV3(for placeId: PlaceId, categories: [String], users: [UserId]) -> AnyPublisher<[Post], APIError> {
        return doRequest(
            endpoint: Endpoint.getCustomMutualPostsV3(placeId: placeId),
            httpMethod: "POST",
            body: CustomPlaceLoadRequest(categories: categories, users: users)
        )
    }
    
    /**
     Get the place icon for the given place.
     */
    func getPlaceIcon(placeId: PlaceId) -> AnyPublisher<MapPlaceIcon, APIError> {
        return doRequest(endpoint: Endpoint.getPlaceIcon(placeId: placeId))
    }
    
    /**
     Get the posts by the given user.
     */
    func getPosts(username: String, cursor: String? = nil, limit: Int? = nil) -> AnyPublisher<FeedResponse, APIError> {
        doRequest(endpoint: Endpoint.posts(username: username, cursor: cursor, limit: limit))
    }
    
    /**
     Get list of followers for given user.
     */
    func getFollowers(username: String, cursor: String? = nil) -> AnyPublisher<FollowFeedResponse, APIError> {
        doRequest(endpoint: Endpoint.followers(username: username, cursor: cursor))
    }
    
    /**
     Get list of followed users for given user.
     */
    func getFollowing(username: String, cursor: String? = nil) -> AnyPublisher<FollowFeedResponse, APIError> {
        doRequest(endpoint: Endpoint.following(username: username, cursor: cursor))
    }
    
    // MARK: - Relation endpoints
    
    /**
     Follow user.
     */
    func followUser(username: String) -> AnyPublisher<FollowUserResponse, APIError> {
        doRequest(endpoint: Endpoint.follow(username: username), httpMethod: "POST")
    }
    
    /**
     Unfollow user.
     */
    func unfollowUser(username: String) -> AnyPublisher<FollowUserResponse, APIError> {
        doRequest(endpoint: Endpoint.unfollow(username: username), httpMethod: "POST")
    }
    
    func blockUser(username: String) -> AnyPublisher<SimpleResponse, APIError> {
        doRequest(endpoint: Endpoint.block(username: username), httpMethod: "POST")
    }
    
    func unblockUser(username: String) -> AnyPublisher<SimpleResponse, APIError> {
        doRequest(endpoint: Endpoint.unblock(username: username), httpMethod: "POST")
    }
    
    /**
     Get follow status.
     */
    func relation(to username: String) -> AnyPublisher<RelationToUser, APIError> {
        doRequest(endpoint: Endpoint.relation(username: username))
    }
    
    // MARK: - Post endpoints
    
    /**
     Create a new post.
     */
    func createPost(_ request: CreatePostRequest) -> AnyPublisher<Post, APIError> {
        return doRequest(endpoint: Endpoint.createPost(), httpMethod: "POST", body: request)
    }
    
    /**
     Get the given post.
     */
    func getPost(_ postId: PostId) -> AnyPublisher<Post, APIError> {
        return doRequest(endpoint: Endpoint.post(postId: postId))
    }
    
    /**
     Edit a post.
     */
    func updatePost(_ postId: PostId, _ request: CreatePostRequest) -> AnyPublisher<Post, APIError> {
        return doRequest(endpoint: Endpoint.post(postId: postId), httpMethod: "PUT", body: request)
    }
    
    /**
     Delete a post.
     */
    func deletePost(postId: PostId) -> AnyPublisher<DeletePostResponse, APIError> {
        return doRequest(endpoint: Endpoint.post(postId: postId), httpMethod: "DELETE")
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
     Save the given post.
     */
    func savePost(postId: PostId) -> AnyPublisher<SimpleResponse, APIError> {
        doRequest(endpoint: Endpoint.savePost(postId: postId), httpMethod: "POST")
    }
    
    /**
     Unsave the given post.
     */
    func unsavePost(postId: PostId) -> AnyPublisher<SimpleResponse, APIError> {
        doRequest(endpoint: Endpoint.unsavePost(postId: postId), httpMethod: "POST")
    }
    
    /**
     Report the given post.
     */
    func reportPost(postId: PostId, details: String) -> AnyPublisher<SimpleResponse, APIError> {
        doRequest(endpoint: Endpoint.reportPost(postId: postId),
                  httpMethod: "POST",
                  body: ReportPostRequest(details: details))
    }
    
    // MARK: - Comment endpoints
    
    func getComments(for postId: PostId, cursor: String? = nil) -> AnyPublisher<CommentPage, APIError> {
        doRequest(endpoint: Endpoint.comments(for: postId, cursor: cursor))
    }
    
    func createComment(for postId: PostId, content: String) -> AnyPublisher<Comment, APIError> {
        doRequest(endpoint: Endpoint.createComment(),
                  httpMethod: "POST",
                  body: CreateCommentRequest(postId: postId, content: content))
    }
    
    func deleteComment(commentId: CommentId) -> AnyPublisher<SimpleResponse, APIError> {
        doRequest(endpoint: Endpoint.comment(commentId: commentId), httpMethod: "DELETE")
    }
    
    func likeComment(commentId: CommentId) -> AnyPublisher<LikeCommentResponse, APIError> {
        doRequest(endpoint: Endpoint.commentLikes(commentId: commentId), httpMethod: "POST")
    }
    
    func unlikeComment(commentId: CommentId) -> AnyPublisher<LikeCommentResponse, APIError> {
        doRequest(endpoint: Endpoint.commentLikes(commentId: commentId), httpMethod: "DELETE")
    }
    
    // MARK: - Search endpoints
    
    func searchUsers(query: String) -> AnyPublisher<[PublicUser], APIError> {
        doRequest(endpoint: Endpoint.searchUser(query: query))
    }
    
    // MARK: - Discover endpoint
    
    func getDiscoverFeed() -> AnyPublisher<[Post], APIError> {
        doRequest(endpoint: Endpoint.discoverFeed())
    }
    
    func uploadImage(imageData: Data) -> AnyPublisher<ImageUploadResponse, APIError> {
        guard let url = Endpoint.uploadImage().url else {
            return Fail(error: APIError.endpointError).eraseToAnyPublisher()
        }
        return getToken()
            .flatMap({ token in
                ImageUploadService.uploadImage(url: url, imageData: imageData, token: token)
                    .tryMap(self.urlSessionPublisherHandler)
                    .mapError({ $0 as? APIError ?? APIError.unknownError })
            })
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: Feedback
    
    func submitFeedback(_ request: FeedbackRequest) -> AnyPublisher<SimpleResponse, APIError> {
        doRequest(endpoint: Endpoint.submitFeedback(), httpMethod: "POST", body: request)
    }
    
    // MARK: - Helpers
    
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
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        return request
    }
    
    /**
     Make a request to the given endpoint and pass the result to the given handler.
     
     - Parameter endpoint: The endpoint.
     */
    private func doRequest<Response: Decodable>(endpoint: Endpoint, httpMethod: String = "GET") -> AnyPublisher<Response, APIError> {
        return doRequest(endpoint: endpoint, httpMethod: httpMethod, body: nil as EmptyBody?)
    }
    
    /**
     Make a request to the given endpoint and pass the result to the given handler.
     
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
            case 400:
                throw APIError.requestError(try? JSONDecoder().decode([String: String].self, from: result.data))
            case 401, 403:
                throw APIError.authError
            case 404:
                throw APIError.notFound
            case 405:
                throw APIError.methodNotAllowed
            case 429:
                throw APIError.rateLimitError
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
            print("could not find key \(key) in JSON: \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            print("could not find type \(type) in JSON: \(context.debugDescription)")
        } catch DecodingError.typeMismatch(let type, let context) {
            print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(let context) {
            print("data found to be corrupted in JSON: \(context.debugDescription)")
        } catch let error as NSError {
            print("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
        }
        throw APIError.decodeError
    }
}

