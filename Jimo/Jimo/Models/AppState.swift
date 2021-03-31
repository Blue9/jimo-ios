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
    case user(PublicUser)
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

class OnboardingModel: ObservableObject {
    @Published var completedContactsOnboarding: Bool = OnboardingModel.contactsOnboarded()
    @Published var completedFeaturedUsersOnboarding: Bool = OnboardingModel.featuredUsersOnboarded()
    
    init() {
        // TODO remove
        // completedContactsOnboarding = false
        // completedFeaturedUsersOnboarding = false
    }
    
    var isUserOnboarded: Bool {
        completedContactsOnboarding && completedFeaturedUsersOnboarding
    }
    
    static func contactsOnboarded() -> Bool {
        // Returns false if the key hasn't been set
        UserDefaults.standard.bool(forKey: "contactsOnboarded")
    }
    
    func setContactsOnboarded() {
        UserDefaults.standard.set(true, forKey: "contactsOnboarded")
        completedContactsOnboarding = true
    }
    
    static func featuredUsersOnboarded() -> Bool {
        // Returns false if the key hasn't been set
        UserDefaults.standard.bool(forKey: "featuredUsersOnboarded")
    }
    
    func setFeaturedUsersOnboarded() {
        UserDefaults.standard.set(true, forKey: "featuredUsersOnboarded")
        completedFeaturedUsersOnboarding = true
    }
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
    let onboardingModel = OnboardingModel()
    
    let storage = Storage.storage()
    
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
    
    // MARK: - User onboarding
    
    func getUsersInContacts(phoneNumbers: [String]) -> AnyPublisher<[PublicUser], APIError> {
        guard case .user = currentUser else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        return apiClient.getUsersInContacts(phoneNumbers: phoneNumbers)
    }
    
    func getSuggestedUsers() -> AnyPublisher<[PublicUser], APIError> {
        return apiClient.getSuggestedUsers()
    }
    
    func followMany(usernames: [String]) -> AnyPublisher<SimpleResponse, APIError> {
        guard case .user = currentUser else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        return apiClient.followMany(usernames: usernames)
    }
    
    // MARK: - Auth
    
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
        } else {
            // Otherwise, just log out
            self.signOutAndClearData()
        }
    }
    
    // MARK: - Invite + waitlist
    
    func getWaitlistStatus() -> AnyPublisher<UserWaitlistStatus, APIError> {
        return self.apiClient.getWaitlistStatus()
    }
    
    func joinWaitlist() -> AnyPublisher<UserWaitlistStatus, APIError> {
        return self.apiClient.joinWaitlist()
    }
    
    func inviteUser(phoneNumber: String) -> AnyPublisher<UserInviteStatus, APIError> {
        return self.apiClient.inviteUser(phoneNumber: phoneNumber)
    }
    
    // MARK: - User
    
    func createUser(_ request: CreateUserRequest) -> AnyPublisher<UserFieldError?, APIError> {
        return self.apiClient.createUser(request)
            .map { response in
                if let user = response.created {
                    self.currentUser = .user(user)
                }
                return response.error
            }
            .eraseToAnyPublisher()
    }
    
    func createUser(
        _ request: CreateUserRequest,
        profilePicture: UIImage
    ) -> AnyPublisher<UserFieldError?, APIError> {
        guard let jpeg = getImageData(for: profilePicture) else {
            return Fail(error: APIError.encodeError).eraseToAnyPublisher()
        }
        return self.apiClient.createUser(request)
            .flatMap { response -> AnyPublisher<UserFieldError?, Never> in
                if let user = response.created {
                    return self.apiClient.uploadProfilePicture(imageData: jpeg)
                        .map { userWithPhoto in
                            self.currentUser = .user(userWithPhoto)
                            return response.error
                        }
                        .catch { error -> AnyPublisher<UserFieldError?, Never> in
                            print("Error when setting profile picture", error)
                            // This will still create the user without the profile picture
                            // Minor inconvenience for the user but it's fine
                            self.currentUser = .user(user)
                            return Just(response.error).eraseToAnyPublisher()
                        }
                        .eraseToAnyPublisher()
                }
                return Just(response.error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
    
    func updateProfile(_ request: UpdateProfileRequest) -> AnyPublisher<UpdateProfileResponse, APIError> {
        guard case .user = currentUser else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        return self.apiClient.updateProfile(request)
            .map({ response in
                if let user = response.user {
                    self.currentUser = .user(user)
                }
                return response
            })
            .eraseToAnyPublisher()
    }
    
    func getPreferences() -> AnyPublisher<UserPreferences, APIError> {
        guard case .user = currentUser else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        return self.apiClient.getPreferences()
    }
    
    func updatePreferences(_ request: UserPreferences) -> AnyPublisher<UserPreferences, APIError> {
        guard case .user = currentUser else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        return self.apiClient.updatePreferences(request)
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
        guard case .user = currentUser else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        return self.apiClient.getFeed()
            .map(self.setFeed)
            .map({ _ in return () })
            .eraseToAnyPublisher()
    }
    
    func loadMoreFeedItems() -> AnyPublisher<Void, APIError> {
        guard case .user = currentUser else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        let beforePostId = feedModel.currentFeed.last
        return self.apiClient.getFeed(beforePostId: beforePostId)
            .map(self.appendToFeed)
            .map({ _ in return () })
            .eraseToAnyPublisher()
    }
    
    func refreshMap() -> AnyPublisher<Void, APIError> {
        return self.apiClient.getMap()
            .map({ posts in self.setMap(posts: posts) })
            .map({ _ in return () })
            .eraseToAnyPublisher()
    }
    
    func followUser(username: String) -> AnyPublisher<FollowUserResponse, APIError> {
        return self.apiClient.followUser(username: username)
    }
    
    func unfollowUser(username: String) -> AnyPublisher<FollowUserResponse, APIError> {
        return self.apiClient.unfollowUser(username: username)
    }
    
    func isFollowing(username: String) -> AnyPublisher<FollowUserResponse, APIError> {
        return self.apiClient.isFollowing(username: username)
    }
    
    // MARK: - Post
    
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
    
    func reportPost(postId: PostId, details: String) -> AnyPublisher<SimpleResponse, APIError> {
        return self.apiClient.reportPost(postId: postId, details: details)
    }
    
    // MARK: - Search
    
    func searchUsers(query: String) -> AnyPublisher<[PublicUser], APIError> {
        return self.apiClient.searchUsers(query: query)
    }
    
    // MARK: - Discover
    
    func discoverFeed() -> AnyPublisher<[Post], APIError> {
        guard case .user = currentUser else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        return self.apiClient.getDiscoverFeed()
            .map(self.setDiscoverFeed)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Feedback
    
    func submitFeedback(_ request: FeedbackRequest) -> AnyPublisher<SimpleResponse, APIError> {
        return self.apiClient.submitFeedback(request)
    }
    
    // MARK: - Notifications
    
    func getNotificationsFeed(token: PaginationToken) -> AnyPublisher<NotificationFeedResponse, APIError> {
        return self.apiClient.getNotificationsFeed(token: token)
            .map(self.addNotificationsToFeed)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Image upload
    
    func uploadImageAndGetId(image: UIImage) -> AnyPublisher<ImageId, APIError> {
        guard apiClient.authClient.currentUser != nil else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        guard case .user(_) = currentUser else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        guard let jpeg = getImageData(for: image) else {
            return Fail(error: APIError.encodeError).eraseToAnyPublisher()
        }
        return apiClient.uploadImage(imageData: jpeg)
            .map({ $0.imageId })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Helpers
    
    private func getImageData(for image: UIImage) -> Data? {
        image.jpegData(compressionQuality: 0.33)
    }
    
    private func addNotificationsToFeed(response: NotificationFeedResponse) -> NotificationFeedResponse {
        var posts: [Post] = []
        for item in response.notifications {
            if let post = item.post {
                posts.append(post)
            }
        }
        _ = addPostsToAllPosts(posts: posts)
        return response
    }
    
    private func setFeed(posts: [Post]) {
        let postIds = addPostsToAllPosts(posts: posts)
        feedModel.currentFeed = postIds
    }
    
    private func appendToFeed(posts: [Post]) {
        let postIds = addPostsToAllPosts(posts: posts)
        feedModel.currentFeed.append(contentsOf: postIds)
    }
    
    private func setDiscoverFeed(posts: [Post]) -> [Post] {
        _ = addPostsToAllPosts(posts: posts)
        return posts
    }
    
    private func setMap(posts: [Post]) {
        _ = addPostsToAllPosts(posts: posts)
        mapModel.posts = posts.map({ $0.postId })
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
        guard case .user(_) = currentUser else {
            registeringToken = false
            return
        }
        self.apiClient.registerNotificationToken(token: token)
            .sink(receiveCompletion: { [weak self] completion in
                self?.registeringToken = false
                if case let .failure(error) = completion {
                    print("Error when registering token, trying again in 5 seconds", error)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self?.registerNewNotificationToken(token: token)
                    }
                }
            }, receiveValue: { response in
                if response.success {
                    print("Registering token")
                    self.setNotificationToken(token: token)
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
            if signingOut {
                self.mapModel.posts.removeAll()
                self.feedModel.currentFeed.removeAll()
                self.allPosts.posts.removeAll()
                self.currentUser = .empty
                self.signingOut = false
            }
        }
    }
}
