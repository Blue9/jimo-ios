//
//  AppState.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/13/21.
//

import Foundation
import Combine
import MapKit
import Firebase


enum CurrentUser {
    case user(User)
    case doesNotExist
    case loading
    case failed
    case empty
}

enum FirebaseSession {
    case user(FirebaseUser)
    case doesNotExist
    case loading
}


class FeedModel: ObservableObject {
    @Published var currentFeed: [PostId] = []
}


class MapModel: ObservableObject {
    @Published var posts: [PostId] = []
}


class UserPosts: ObservableObject {
    @Published var posts: [PostId] = []
}


class AllPosts: ObservableObject {
    @Published var posts: [PostId: Post] = [:]
}


class AppState: ObservableObject {
    private var apiClient: APIClient
    private var cancelBag: Set<AnyCancellable> = .init()
    
    @Published var currentUser: CurrentUser = .empty
    @Published var firebaseSession: FirebaseSession = .loading
    
    /// App state vars
    let feedModel = FeedModel()
    let mapModel = MapModel()
    let userPosts = UserPosts()
    let allPosts = AllPosts()
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func listen() {
        self.apiClient.setAuthHandler(handle: self.authHandler)
    }
    
    func signUp(email: String, password: String) -> AnyPublisher<AuthDataResult, Error> {
        return apiClient.authClient.signUp(email: email, password: password)
    }
    
    func signIn(email: String, password: String) -> AnyPublisher<AuthDataResult, Error> {
        return apiClient.authClient.signIn(email: email, password: password)
    }
    
    func verifyPhoneNumber(phoneNumber: String) -> AnyPublisher<String, Error> {
        return apiClient.authClient.verifyPhoneNumber(phoneNumber: phoneNumber)
            .map({ verificationID in
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                return verificationID
            })
            .eraseToAnyPublisher()
    }
    
    func getPhoneVerificationID() -> String? {
        return UserDefaults.standard.string(forKey: "authVerificationID")
    }
    
    func signInPhone(verificationCode: String) -> AnyPublisher<AuthDataResult, Error> {
        guard let verificationID = getPhoneVerificationID() else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        return apiClient.authClient.signInPhone(verificationID: verificationID, verificationCode: verificationCode)
    }
    
    func forgotPassword(email: String) -> AnyPublisher<Void, Error> {
        return apiClient.authClient.forgotPassword(email: email)
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
        self.currentUser = .empty
    }
    
    func getWaitlistStatus() -> AnyPublisher<UserWaitlistStatus, APIError> {
        return self.apiClient.getWaitlistStatus()
    }
    
    func joinWaitlist() -> AnyPublisher<UserWaitlistStatus, APIError> {
        return self.apiClient.joinWaitlist()
    }
    
    func inviteUser(phoneNumber: String) -> AnyPublisher<UserInviteStatus, APIError> {
        return self.apiClient.inviteUser(phoneNumber: phoneNumber)
    }
    
    func createUser(_ request: CreateUserRequest) -> AnyPublisher<CreateUserResponse, APIError> {
        return self.apiClient.createUser(request)
            .map({ response in
                if let user = response.created {
                    self.currentUser = .user(user)
                }
                return response
            })
            .eraseToAnyPublisher()
    }
    
    func getUser(username: String) -> AnyPublisher<PublicUser, APIError> {
        return self.apiClient.getUser(username: username)
    }
    
    func refreshCurrentUser() {
        self.currentUser = .loading
        self.apiClient.getMe()
            .map({ CurrentUser.user($0) })
            .catch({ error in
                return Just(error == .notFound ? CurrentUser.doesNotExist : CurrentUser.failed)
            })
            .assign(to: \.currentUser, on: self)
            .store(in: &self.cancelBag)
    }
    
    func refreshFeed() -> AnyPublisher<Void, APIError> {
        guard case let CurrentUser.user(user) = self.currentUser else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        return self.apiClient.getFeed(username: user.username)
            .map(self.setFeed)
            .map({ _ in return () })
            .eraseToAnyPublisher()
    }
    
    func refreshMap(region: MKCoordinateRegion) -> AnyPublisher<Void, APIError> {
        return self.apiClient.getMap(region: region)
            .map(self.setMap)
            .map({ _ in return () })
            .eraseToAnyPublisher()
    }
    
    func createPost(_ request: CreatePostRequest) -> AnyPublisher<Void, APIError> {
        return self.apiClient.createPost(request)
            .map(self.newPost)
            .map({ _ in return () })
            .eraseToAnyPublisher()
    }
    
    func deletePost(postId: PostId) -> AnyPublisher<Void, APIError> {
        return self.apiClient.deletePost(postId: postId)
            .map({
                if $0.deleted {
                    self.removePost(postId: postId)
                }
            })
            .eraseToAnyPublisher()
    }
    
    func getPosts(username: String) -> AnyPublisher<[PostId], APIError> {
        return self.apiClient.getPosts(username: username)
            .map(self.addPostsToAllPosts)
            .eraseToAnyPublisher()
    }
    
    func likePost(postId: PostId) -> AnyPublisher<Void, APIError> {
        return self.apiClient.likePost(postId: postId)
            .map({ response in
                self.updatePostLikes(postId: postId, liked: true, likes: response.likes)
            })
            .eraseToAnyPublisher()
    }
    
    func unlikePost(postId: PostId) -> AnyPublisher<Void, APIError> {
        return self.apiClient.unlikePost(postId: postId)
            .map({ response in
                self.updatePostLikes(postId: postId, liked: false, likes: response.likes)
            })
            .eraseToAnyPublisher()
    }
    
    private func setFeed(posts: [Post]) {
        posts.forEach({ post in allPosts.posts[post.postId] = post })
        feedModel.currentFeed = posts.map(\.postId)
    }
    
    private func setMap(posts: [Post]) {
        posts.forEach({ post in
            allPosts.posts[post.postId] = post
            if !mapModel.posts.contains(post.postId) {
                mapModel.posts.append(post.postId)
            }
        })
    }
    
    private func addPostsToAllPosts(posts: [Post]) -> [PostId] {
        posts.forEach({ post in
            if allPosts.posts[post.postId] != post {
                allPosts.posts[post.postId] = post
            }
        })
        return posts.map(\.postId)
    }
    
    private func newPost(post: Post) {
        allPosts.posts[post.postId] = post
        userPosts.posts.append(post.postId)
        feedModel.currentFeed.insert(post.postId, at: 0)
    }
    
    private func removePost(postId: PostId) {
        userPosts.posts.removeAll(where: { $0 == postId })
        feedModel.currentFeed.removeAll(where: { $0 == postId })
        mapModel.posts.removeAll(where: { $0 == postId })
        allPosts.posts.removeValue(forKey: postId)
    }
    
    private func updatePostLikes(postId: PostId, liked: Bool, likes: Int) {
        guard let post = allPosts.posts[postId] else {
            print("Cannot update likes for post, does not exist", postId)
            return
        }
        allPosts.posts[postId] = Post(
            postId: post.postId,
            user: post.user,
            place: post.place,
            category: post.category,
            content: post.content,
            imageUrl: post.imageUrl,
            createdAt: post.createdAt,
            likeCount: likes,
            liked: liked,
            customLocation: post.customLocation)
    }
    
    private func authHandler(auth: Firebase.Auth, user: Firebase.User?) {
        if let user = user {
            self.refreshCurrentUser()
            self.firebaseSession = .user(FirebaseUser(uid: user.uid, email: user.email))
        } else {
            self.firebaseSession = .doesNotExist
            self.currentUser = .empty
        }
    }
}
