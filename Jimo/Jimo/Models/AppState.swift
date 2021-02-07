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
    let allPosts = AllPosts()
    
    // If we're signing out don't register any new FCM tokens
    var signingOut = false
    var registeringToken = false
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
        updateTokenOnUserChange()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveTokenUpdate(_:)),
            name: Notification.Name(rawValue: "FCMToken"),
            object: nil)
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
     Sign the current user out and remove the notification token. Does nothing if the user was already signed out.
     Returns whether the user could be successfully signed out.
     */
    func signOut() {
        signingOut = true
        if registeringToken {
            // Fail. We could try again in a few seconds but this is so unlikely it's not worth doing
            signingOut = false
            return
        }
        let registeredToken = getNotificationToken()
        guard let token = registeredToken else {
            self.signOutAndClearData()
            return
        }
        if case .user(_) = currentUser {
            // Logged in, that means we must have registered the token
            self.apiClient.removeNotificationToken(token: token)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("Error when removing notification token", error)
                    }
                }, receiveValue: { [weak self] status in
                    if status.success {
                        self?.signOutAndClearData()
                    }
                    self?.signingOut = false
                })
                .store(in: &cancelBag)
        }
        // Otherwise, just log out
        self.signOutAndClearData()
        signingOut = false
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
            .map({ posts in self.setMap(region: region, posts: posts) })
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
    
    private func setMap(region: MKCoordinateRegion, posts: [Post]) {
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
        feedModel.currentFeed.insert(post.postId, at: 0)
        mapModel.posts.append(post.postId)
    }
    
    private func removePost(postId: PostId) {
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
    
    private func signOutAndClearData() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Already logged out")
        }
        self.mapModel.posts.removeAll()
        self.feedModel.currentFeed.removeAll()
        self.allPosts.posts.removeAll()
        self.currentUser = .empty
    }
    
    // MARK: - Notification logic
    
    private func updateTokenOnUserChange() {
        $currentUser.sink(receiveValue: { [weak self] user in
            if case .user(_) = user {
                self?.registerNotificationToken()
            }
        })
        .store(in: &cancelBag)
    }
    
    @objc private func didReceiveTokenUpdate(_ notification: Notification) {
        guard let dataDict = notification.userInfo else {
            return
        }
        guard let token = dataDict["token"] as? String else {
            print("Missing token")
            return
        }
        print("Received notification for new token", token)
        registerNewNotificationToken(token: token)
    }
    
    private func getNotificationToken() -> String? {
        let key = "registeredFCMToken"
        return UserDefaults.standard.string(forKey: key)
    }
    
    private func setNotificationToken(token: String) {
        let key = "registeredFCMToken"
        UserDefaults.standard.set(token, forKey: key)
    }
    
    private func registerNotificationToken() {
        print("Registering token")
        Messaging.messaging().token { [weak self] token, error in
            guard let self = self else {
                return
            }
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
                self.registerNewNotificationToken(token: token)
            }
        }
    }
    
    private func registerNewNotificationToken(token: String) {
        registeringToken = true
        if signingOut {
            registeringToken = false
            return
        }
        self.apiClient.registerNotificationToken(token: token)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    print("Error when registering token", error)
                    // TODO try again
                }
                self?.registeringToken = false
            }, receiveValue: { [weak self] response in
                if response.success {
                    self?.setNotificationToken(token: token)
                }
            })
            .store(in: &self.cancelBag)
    }
    
    private func authHandler(auth: Firebase.Auth, user: Firebase.User?) {
        if let user = user {
            self.refreshCurrentUser()
            self.firebaseSession = .user(FirebaseUser(uid: user.uid, phoneNumber: user.phoneNumber))
        } else {
            self.firebaseSession = .doesNotExist
            self.currentUser = .empty
        }
    }
}
