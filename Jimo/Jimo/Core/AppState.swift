//
//  AppState.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/13/21.
//

// swiftlint:disable type_body_length
// swiftlint:disable file_length
import SwiftUI
import Combine
import MapKit
import Firebase
import SDWebImage

enum CurrentUser {
    case user(PublicUser)
    case deactivated
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

class LocalSettings: ObservableObject {
    @Published var clusteringEnabled = false
}

enum OnboardingStep: Int {
    case completed = -1,
    requestLocation = 1,
    requestContacts = 2,
    followContacts = 3,
    followFeatured = 4,
    requestNotifications = 5
}

class OnboardingModel: ObservableObject {
    @AppStorage("onboardingStep") var onboardingStep: OnboardingStep = .requestLocation {
        willSet {
            objectWillChange.send() // Required for iOS 14.4 and lower
        }
    }

    init() {
        // Uncomment to reset onboarding view
        // onboardingStep = .requestLocation
    }

    var isUserOnboarded: Bool {
        onboardingStep == .completed
    }

    func step() {
        withAnimation {
            if self.onboardingStep == .requestContacts && PermissionManager.shared.contactsAuthStatus() != .authorized {
                // Didn't receive contacts permission, skip followContacts
                self.onboardingStep = .followFeatured
            } else {
                // Go to next step
                self.onboardingStep = .init(rawValue: self.onboardingStep.rawValue + 1) ?? .completed
            }
        }
    }
}

class AppState: ObservableObject {
    private var apiClient: APIClient
    private var cancelBag: Set<AnyCancellable> = .init()
    private var dateTimeFormatter = RelativeDateTimeFormatter()

    @Published var currentUser: CurrentUser = .loading
    @Published var firebaseSession: FirebaseSession = .loading

    @Published var unreadNotifications: Int = UIApplication.shared.applicationIconBadgeNumber {
        didSet {
            UIApplication.shared.applicationIconBadgeNumber = unreadNotifications
        }
    }

    let onboardingModel = OnboardingModel()
    var localSettings = LocalSettings()

    let userPublisher = UserPublisher()
    let postPublisher = PostPublisher()
    let placePublisher = PlacePublisher()
    let commentPublisher = CommentPublisher()

    // If we're signing out don't register any new FCM tokens
    var signingOut = false
    var registeringToken = false

    var me: PublicUser? {
        if case let .user(user) = currentUser {
            return user
        }
        return nil
    }

    init(apiClient: APIClient) {
        // Uncomment the two lines below to clear the image cache
        // SDImageCache.shared.clearMemory()
        // SDImageCache.shared.clearDisk()

        self.apiClient = apiClient
        updateTokenOnUserChange()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveTokenUpdate(_:)),
            name: Notification.Name(rawValue: "FCMToken"),
            object: nil)
    }

    func relativeTime(for date: Date) -> String {
        if Date().timeIntervalSince(date) < 1 {
            return "just now"
        }
        return dateTimeFormatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - User onboarding

    func getUsersInContacts(phoneNumbers: [String]) -> AnyPublisher<[PublicUser], APIError> {
        guard case .user = currentUser else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        return apiClient.getUsersInContacts(phoneNumbers: phoneNumbers)
    }

    func getFeaturedUsers() -> AnyPublisher<[PublicUser], APIError> {
        return apiClient.getFeaturedUsers()
    }

    func getSuggestedUsers() -> AnyPublisher<SuggestedUsersResponse, APIError> {
        return apiClient.getSuggestedUsers()
    }

    func followMany(usernames: [String]) -> AnyPublisher<SimpleResponse, APIError> {
        guard case .user = currentUser else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        return apiClient.followMany(usernames: usernames)
            .map { response in
                for username in usernames {
                    self.userPublisher.userRelationChanged(username: username, relation: .following)
                }
                return response
            }
            .eraseToAnyPublisher()
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
            self.signOutFirebase()
            return
        }
        if case .user = currentUser {
            // Logged in, that means we must have registered the token
            self.apiClient.removeNotificationToken(token: token)
                .sink(receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("Error when removing notification token", error)
                    }
                }, receiveValue: { [weak self] status in
                    if status.success {
                        self?.signOutFirebase()
                    }
                    self?.signingOut = false
                })
                .store(in: &cancelBag)
        } else {
            // Otherwise, just log out
            self.signOutFirebase()
        }
    }

    func signOutFirebase() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Already logged out")
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
                    DispatchQueue.main.async {
                        self.currentUser = .user(user)
                    }
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
                            DispatchQueue.main.async {
                                self.currentUser = .user(userWithPhoto)
                            }
                            return response.error
                        }
                        .catch { error -> AnyPublisher<UserFieldError?, Never> in
                            print("Error when setting profile picture", error)
                            // This will still create the user without the profile picture
                            // Minor inconvenience for the user but it's fine
                            DispatchQueue.main.async {
                                self.currentUser = .user(user)
                            }
                            return Just(response.error).eraseToAnyPublisher()
                        }
                        .eraseToAnyPublisher()
                }
                return Just(response.error).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func deleteUser() -> AnyPublisher<SimpleResponse, APIError> {
        self.apiClient.deleteUser()
    }

    func updateProfile(_ request: UpdateProfileRequest) -> AnyPublisher<UpdateProfileResponse, APIError> {
        guard case .user = currentUser else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        return self.apiClient.updateProfile(request)
            .map({ response in
                if let user = response.user {
                    DispatchQueue.main.async {
                        self.currentUser = .user(user)
                    }
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
            .catch({ error -> Just<CurrentUser> in
                switch error {
                case .notFound:
                    return Just(CurrentUser.doesNotExist)
                case .gone:
                    return Just(CurrentUser.deactivated)
                default:
                    return Just(CurrentUser.failed)
                }
            })
            .assign(to: \.currentUser, on: self)
            .store(in: &self.cancelBag)
    }

    func getSavedPosts(cursor: String? = nil) -> AnyPublisher<FeedResponse, APIError> {
        return self.apiClient.getSavedPosts(cursor: cursor)
    }

    func refreshFeed() -> AnyPublisher<FeedResponse, APIError> {
        return self.apiClient.getFeed()
    }

    func loadMoreFeedItems(cursor: String? = nil) -> AnyPublisher<FeedResponse, APIError> {
        return self.apiClient.getFeed(cursor: cursor)
    }

    func getFollowers(username: String, cursor: String? = nil) -> AnyPublisher<FollowFeedResponse, APIError> {
        return self.apiClient.getFollowers(username: username, cursor: cursor)
    }

    func getFollowing(username: String, cursor: String? = nil) -> AnyPublisher<FollowFeedResponse, APIError> {
        return self.apiClient.getFollowing(username: username, cursor: cursor)
    }

    // MARK: - Map endpoints

    func getMap(
        region: RectangularRegion,
        categories: [String],
        mapType: MapType,
        userIds: [UserId]
    ) -> AnyPublisher<MapResponse, APIError> {
        self.apiClient.getMap(
            request: .init(
                region: region,
                categories: categories,
                mapType: mapType,
                userIds: userIds
            )
        )
    }

    // MARK: - Place endpoints

    func findPlace(
        name: String,
        latitude: Double,
        longitude: Double
    ) -> AnyPublisher<FindPlaceResponse, APIError> {
        self.apiClient.findPlace(name: name, latitude: latitude, longitude: longitude)
    }

    func getPlaceDetails(placeId: PlaceId) -> AnyPublisher<GetPlaceDetailsResponse, APIError> {
        self.apiClient.getPlaceDetails(placeId: placeId)
    }

    func getSavedPlaces() -> AnyPublisher<SavedPlacesResponse, APIError> {
        apiClient.getSavedPlaces()
    }

    func savePlace(
        placeId: PlaceId? = nil,
        maybeCreatePlaceRequest: MaybeCreatePlaceRequest? = nil,
        note: String
    ) -> AnyPublisher<SavePlaceResponse, APIError> {
        apiClient.savePlace(
            SavePlaceRequest(
                place: maybeCreatePlaceRequest,
                placeId: placeId,
                note: note
            )
        ).map {
            self.placePublisher.placeSaved(.init(placeId: $0.save.place.placeId, save: $0.save, createPlaceRequest: maybeCreatePlaceRequest))
            return $0
        }.eraseToAnyPublisher()
    }

    func unsavePlace(_ placeId: PlaceId) -> AnyPublisher<SimpleResponse, APIError> {
        apiClient.unsavePlace(placeId)
            .map {
                self.placePublisher.placeUnsaved(placeId)
                return $0
            }.eraseToAnyPublisher()
    }

    // MARK: - Relation endpoints

    func followUser(username: String) -> AnyPublisher<FollowUserResponse, APIError> {
        return self.apiClient.followUser(username: username)
            .map { response in
                self.userPublisher.userRelationChanged(username: username, relation: .following)
                return response
            }
            .eraseToAnyPublisher()
    }

    func unfollowUser(username: String) -> AnyPublisher<FollowUserResponse, APIError> {
        return self.apiClient.unfollowUser(username: username)
            .map { response in
                self.userPublisher.userRelationChanged(username: username, relation: nil)
                return response
            }
            .eraseToAnyPublisher()
    }

    func blockUser(username: String) -> AnyPublisher<SimpleResponse, APIError> {
        return self.apiClient.blockUser(username: username)
            .map { response in
                self.userPublisher.userRelationChanged(username: username, relation: .blocked)
                return response
            }
            .eraseToAnyPublisher()
    }

    func unblockUser(username: String) -> AnyPublisher<SimpleResponse, APIError> {
        return self.apiClient.unblockUser(username: username)
            .map { response in
                self.userPublisher.userRelationChanged(username: username, relation: nil)
                return response
            }
            .eraseToAnyPublisher()
    }

    func relation(to username: String) -> AnyPublisher<RelationToUser, APIError> {
        return self.apiClient.relation(to: username)
    }

    // MARK: - Post

    func createPost(_ request: CreatePostRequest) -> AnyPublisher<Post, APIError> {
        return self.apiClient.createPost(request)
            .map { post in
                self.postPublisher.postCreated(post: post)
                Analytics.track(.postCreated, parameters: [
                    "category": request.category,
                    "hasCaption": request.content.count > 0,
                    "hasPhoto": request.imageId != nil
                ])
                return post
            }
            .eraseToAnyPublisher()
    }

    func getPost(_ postId: PostId) -> AnyPublisher<Post, APIError> {
        return self.apiClient.getPost(postId)
    }

    func updatePost(_ postId: PostId, _ request: CreatePostRequest) -> AnyPublisher<Post, APIError> {
        return self.apiClient.updatePost(postId, request)
            .map { post in
                self.postPublisher.postUpdated(post: post)
                Analytics.track(.postUpdated, parameters: [
                    "category": request.category,
                    "hasCaption": request.content.count > 0,
                    "hasPhoto": request.imageId != nil
                ])
                return post
            }
            .eraseToAnyPublisher()
    }

    func deletePost(postId: PostId) -> AnyPublisher<Void, APIError> {
        return self.apiClient.deletePost(postId: postId)
            .map { _ in
                self.postPublisher.postDeleted(postId: postId)
                Analytics.track(.postDeleted)
            }
            .eraseToAnyPublisher()
    }

    func getPosts(username: String, cursor: String? = nil, limit: Int? = nil) -> AnyPublisher<FeedResponse, APIError> {
        return self.apiClient.getPosts(username: username, cursor: cursor, limit: limit)
    }

    func likePost(postId: PostId) -> AnyPublisher<LikePostResponse, APIError> {
        return self.apiClient.likePost(postId: postId)
            .map { like in
                self.postPublisher.postLiked(postId: postId, likeCount: like.likes)
                Analytics.track(.postLiked)
                return like
            }
            .eraseToAnyPublisher()
    }

    func unlikePost(postId: PostId) -> AnyPublisher<LikePostResponse, APIError> {
        return self.apiClient.unlikePost(postId: postId)
            .map { like in
                self.postPublisher.postUnliked(postId: postId, likeCount: like.likes)
                Analytics.track(.postUnliked)
                return like
            }
            .eraseToAnyPublisher()
    }

    func reportPost(postId: PostId, details: String) -> AnyPublisher<SimpleResponse, APIError> {
        return self.apiClient.reportPost(postId: postId, details: details)
    }

    // MARK: - Comment

    func getComments(for postId: PostId, cursor: String? = nil) -> AnyPublisher<CommentPage, APIError> {
        apiClient.getComments(for: postId, cursor: cursor)
    }

    func createComment(for postId: PostId, content: String) -> AnyPublisher<Comment, APIError> {
        apiClient.createComment(for: postId, content: content)
            .map { comment in
                self.commentPublisher.commentCreated(comment: comment)
                Analytics.track(.commentCreated)
                return comment
            }
            .eraseToAnyPublisher()
    }

    func deleteComment(commentId: CommentId) -> AnyPublisher<SimpleResponse, APIError> {
        apiClient.deleteComment(commentId: commentId)
            .map { response in
                self.commentPublisher.commentDeleted(commentId: commentId)
                Analytics.track(.commentDeleted)
                return response
            }
            .eraseToAnyPublisher()
    }

    func likeComment(commentId: CommentId) -> AnyPublisher<LikeCommentResponse, APIError> {
        apiClient.likeComment(commentId: commentId)
            .map { response in
                self.commentPublisher.commentLikes(commentId: commentId, likeCount: response.likes, liked: true)
                return response
            }
            .eraseToAnyPublisher()
    }

    func unlikeComment(commentId: CommentId) -> AnyPublisher<LikeCommentResponse, APIError> {
        apiClient.unlikeComment(commentId: commentId)
            .map { response in
                self.commentPublisher.commentLikes(commentId: commentId, likeCount: response.likes, liked: false)
                return response
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Search

    func searchUsers(query: String) -> AnyPublisher<[PublicUser], APIError> {
        return self.apiClient.searchUsers(query: query)
    }

    // MARK: - Discover

    func discoverFeedV2(location: Location? = nil) -> AnyPublisher<FeedResponse, APIError> {
        guard case .user = currentUser else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        return self.apiClient.getDiscoverFeedV2(location: location)
    }

    // MARK: - Feedback

    func submitFeedback(_ request: FeedbackRequest) -> AnyPublisher<SimpleResponse, APIError> {
        return self.apiClient.submitFeedback(request)
    }

    // MARK: - Notifications

    func getNotificationsFeed(token: String?) -> AnyPublisher<NotificationFeedResponse, APIError> {
        return self.apiClient.getNotificationsFeed(token: token)
            .eraseToAnyPublisher()
    }

    // MARK: - Image upload

    func uploadImageAndGetId(image: UIImage) -> AnyPublisher<ImageId, APIError> {
        guard apiClient.authClient.currentUser != nil else {
            return Fail(error: APIError.authError).eraseToAnyPublisher()
        }
        guard case .user = currentUser else {
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
        image.jpegData(compressionQuality: 0.67)
    }

    // MARK: - Notification logic

    private func updateTokenOnUserChange() {
        $currentUser.sink(receiveValue: { [weak self] user in
            if case .user = user {
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
        // print("Received notification for new token", token)
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
                // print("FCM registration token: \(token)")
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
        guard case .user = currentUser else {
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
        DispatchQueue.main.async {
            if let user = user {
                self.firebaseSession = .user(FirebaseUser(uid: user.uid, phoneNumber: user.phoneNumber))
                self.refreshCurrentUser()
            } else {
                if self.signingOut {
                    self.signingOut = false
                }
                self.firebaseSession = .doesNotExist
                self.currentUser = .empty
            }
        }
    }
}
// swiftlint:enable type_body_length
// swiftlint:enable file_length
