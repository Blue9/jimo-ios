//
//  MapViewModelV2.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/7/22.
//

import Foundation
import MapKit
import Combine


enum MapLoadStatus {
    case loading, failed, success
}

struct MapPins: Equatable {
    var loaded = false
    var pins: [MapPlace] = []
}


class MapViewModelV2: ObservableObject {
    let locationManager = CLLocationManager()
    let nc = NotificationCenter.default
    
    private var cancelBag: Set<AnyCancellable> = .init()
    
    // Used when loading the map from the server
    @Published var loadStatus: MapLoadStatus = .loading
    
    // Used when the filters change
    @Published var filterLoading = false
    
    /// Unfiltered data
    @Published var allPosts: [PostId: Post] = [:] {
        didSet {
            updatePostCountsByUser()
        }
    }
    @Published var allUsers: [UserId: PublicUser] = [:]
    @Published var numLoadedPostsByUser: [UserId: Int] = [:]
    @Published var postCursorsByUser: [UserId: PostId?] = [:]
    @Published var userSearchResults: [PublicUser] = []
    
    /// Filters
    @Published var filterUsersQuery: String = ""
    @Published var selectedCategories: Set<String> = [
        "food",
        "activity",
        "nightlife",
        "attraction",
        "lodging",
        "shopping"
    ] {
        didSet {
            if selectedCategories != oldValue {
                self.updateSelectedPosts()
            }
        }
    }
    
    @Published var selectedUsers: Set<UserId> = .init() {
        didSet {
            if selectedUsers != oldValue {
                self.updateSelectedPosts()
            }
        }
    }
    
    @Published var selectedPosts: Set<PostId> = .init() {
        didSet {
            if selectedPosts != oldValue {
                DispatchQueue.global(qos: .userInteractive).async {
                    self.updateMapPins(selectedPosts: self.selectedPosts)
                }
            }
        }
    }
    
    /// Helpful properties
    var allUsersSelected: Bool {
        selectedUsers.count == allUsers.count
    }
    
    var noUsersSelected: Bool {
        selectedUsers.isEmpty
    }
    
    /// Computed pins after filtering
    @Published var mapPins: MapPins = MapPins()
    
    init() {
        nc.addObserver(self, selector: #selector(postCreated), name: PostPublisher.postCreated, object: nil)
        nc.addObserver(self, selector: #selector(postLiked), name: PostPublisher.postLiked, object: nil)
        nc.addObserver(self, selector: #selector(postDeleted), name: PostPublisher.postDeleted, object: nil)
    }
    
    func listenToSearchQuery(appState: AppState, globalViewState: GlobalViewState) {
        $filterUsersQuery
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.search(appState: appState, globalViewState: globalViewState, query: query)
            }
            .store(in: &cancelBag)
    }
    
    /// API calls
    
    func refreshMap(appState: AppState, globalViewState: GlobalViewState) {
        loadStatus = .loading
        appState.getMapV2()
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.loadStatus = .failed
                    print("Error loading map", error)
                    globalViewState.setError("Could not load map")
                }
            } receiveValue: { [weak self] map in
                self?.loadStatus = .success
                self?.postCursorsByUser = map.postCursorsByUser
                guard !map.posts.isEmpty else {
                    self?.mapPins.loaded = true
                    return
                }
                self?.allPosts = map.posts.reduce(into: [PostId: Post]()) { (result, post) in
                    result[post.id] = post
                }
                self?.updateAllUsers()
            }
            .store(in: &cancelBag)
    }
    
    private func search(appState: AppState, globalViewState: GlobalViewState, query: String) {
        appState.searchUsers(query: query)
            .catch { error -> AnyPublisher<[PublicUser], Never> in
                print("Error when searching", error)
                if query.isEmpty {
                    globalViewState.setError("Could not load suggested users")
                }
                return Empty().eraseToAnyPublisher()
            }
            .sink { [weak self] results in
                self?.userSearchResults = results
            }
            .store(in: &cancelBag)
    }
    
    private func loadMorePosts(
        appState: AppState,
        globalViewState: GlobalViewState,
        forUser user: PublicUser,
        onLoad: @escaping (_ success: Bool) -> ()
    ) {
        appState.getPosts(username: user.username, cursor: postCursorsByUser[user.id] ?? nil, limit: 100)
            .sink { completion in
                if case .failure = completion {
                    globalViewState.setError("Could not load posts")
                    onLoad(false)
                }
            } receiveValue: { [weak self] response in
                self?.postCursorsByUser[user.id] = response.cursor
                if let post = response.posts.first {
                    self?.allUsers[post.user.id] = post.user // In case the post count of the user has updated
                }
                for post in response.posts {
                    self?.allPosts[post.id] = post
                }
                onLoad(true)
            }
            .store(in: &cancelBag)
    }
    
    /// Helper functions called by views
    
    func preselectPost(post: Post) {
        let newPin = MapPlace(
            place: post.place,
            icon: MapPlaceIcon(
                category: post.category,
                iconUrl: post.user.profilePictureUrl,
                numMutualPosts: 1
            ),
            posts: [post.id]
        )
        allPosts[post.id] = post
        mapPins.pins.append(newPin)
    }
    
    func selectAllUsers() {
        selectedUsers = Set(allUsers.keys)
    }
    
    func selectAndLoadPostsIfNotLoaded(
        appState: AppState,
        globalViewState: GlobalViewState,
        user: PublicUser,
        onComplete: @escaping () -> ()
    ) {
        guard allUsers[user.id] == nil else {
            self.selectedUsers.insert(user.id)
            onComplete()
            return
        }
        self.loadMorePosts(appState: appState, globalViewState: globalViewState, forUser: user) { success in
            self.allUsers[user.id] = user
            self.selectedUsers.insert(user.id) // Will automatically update selected posts
            onComplete()
        }
    }
    
    func clearUserSelection() {
        selectedUsers.removeAll()
    }
    
    func isSelected(userId: UserId) -> Bool {
        selectedUsers.contains(userId)
    }
    
    func loadMoreAndUpdateMap(
        appState: AppState,
        globalViewState: GlobalViewState,
        forUser user: PublicUser,
        onComplete: @escaping () -> ()
    ) {
        self.loadMorePosts(appState: appState, globalViewState: globalViewState, forUser: user) { success in
            if success {
                self.updateSelectedPosts()
                onComplete()
            }
        }
    }
    
    ///
    
    func sortUsersHelper(_ user1: PublicUser, _ user2: PublicUser) -> Bool {
        user1.username.caseInsensitiveCompare(user2.username) == .orderedAscending
    }
    
    @objc private func postCreated(notification: Notification) {
        let post = notification.object as! Post
        allPosts[post.id] = post
    }
    
    @objc private func postLiked(notification: Notification) {
        let like = notification.object as! PostLikePayload
        allPosts[like.postId]?.liked = like.liked
        allPosts[like.postId]?.likeCount = like.likeCount
    }
    
    @objc private func postDeleted(notification: Notification) {
        let postId = notification.object as! PostId
        allPosts.removeValue(forKey: postId)
        selectedPosts.remove(postId)
        for i in mapPins.pins.indices {
            mapPins.pins[i].posts.removeAll(where: { $0 == postId })
        }
    }
    
    /// Handle data updates
    
    private func updatePostCountsByUser() {
        self.numLoadedPostsByUser = allPosts.values.reduce(into: [UserId: Int]()) { (result, post) in
            let current = result[post.user.id] ?? 0
            result[post.user.id] = current + 1
        }
    }
    
    private func updateAllUsers() {
        let allUsers = allPosts.values.reduce(into: [UserId: PublicUser]()) { (result, post) in
            result[post.user.id] = post.user
        }
        let allUserIds = Set(allUsers.keys)
        let newSelectedUsers = self.selectedUsers.isEmpty ? allUserIds : allUserIds.filter({ self.selectedUsers.contains($0) })
        DispatchQueue.main.async {
            self.allUsers = allUsers
            self.selectedUsers = newSelectedUsers
        }
    }
    
    private func updateSelectedPosts() {
        let selected = allPosts
            .filter { (postId, post) in
                selectedUsers.contains(post.user.id) && selectedCategories.contains(post.category)
            }
        let selectedPosts = Set(selected.keys)
        DispatchQueue.main.async {
            self.selectedPosts = selectedPosts
        }
    }
    
    private func updateMapPins(selectedPosts: Set<PostId>) {
        // TODO clean up
        let postsByPlace = selectedPosts.reduce(into: [PlaceId: [PostId]]()) { (result, postId) in
            guard let post = allPosts[postId] else {
                return
            }
            let placeId = post.place.placeId
            if result[placeId] != nil {
                result[placeId]?.append(postId)
            } else {
                result[placeId] = [postId]
            }
        }
        let places = selectedPosts.reduce(into: [PlaceId: Place]()) { (result, postId) in
            if let post = allPosts[postId], result[post.place.placeId] == nil {
                result[post.place.placeId] = post.place
            }
        }
        let placeImages = selectedPosts.reduce(into: [PlaceId: String]()) { (result, postId) in
            if let post = allPosts[postId], result[post.place.placeId] == nil {
                result[post.place.placeId] = post.user.profilePictureUrl
            }
        }
        let placeMutualPosts = selectedPosts.reduce(into: [PlaceId: Int]()) { (result, postId) in
            guard let post = allPosts[postId] else {
                return
            }
            if let count = result[post.place.placeId] {
                result[post.place.placeId] = count + 1
            } else {
                result[post.place.placeId] = 1
            }
        }
        let placeCategories = selectedPosts.reduce(into: [PlaceId: String]()) { (result, postId) in
            if let post = allPosts[postId], result[post.place.placeId] == nil {
                result[post.place.placeId] = post.category
            }
        }
        let mapPins = places.reduce(into: [MapPlace]()) { (result, item) in
            result.append(MapPlace(place: item.value, icon: MapPlaceIcon(
                category: placeCategories[item.key],
                iconUrl: placeImages[item.key],
                numMutualPosts: placeMutualPosts[item.key] ?? 1
            ), posts: postsByPlace[item.key]?.sorted(by: { $0.compare($1) == .orderedDescending }) ?? []))
        }
        let result = greedyTravelingSalesman(pins: mapPins)
        DispatchQueue.main.async {
            if self.selectedPosts == selectedPosts {
                self.mapPins = MapPins(loaded: true, pins: result)
            }
        }
    }
    
    private func greedyTravelingSalesman(pins: [MapPlace]) -> [MapPlace] {
        // Return the list of pins in a somewhat reasonable order
        guard pins.count > 0 else {
            return []
        }
        // Get distance between every point, first int must be < second
        var distances: [[Double]] = [[Double]](repeating: [Double](repeating: -1, count: pins.count), count: pins.count)
        for i in 0..<pins.count-1 {
            for j in i+1..<pins.count {
                let iLocation = MKMapPoint(pins[i].place.location.coordinate())
                let jLocation = MKMapPoint(pins[j].place.location.coordinate())
                let distance = iLocation.distance(to: jLocation).magnitude
                distances[i][j] = distance
                distances[j][i] = distance
            }
        }
        
        var chain: [Int] = [0]
        var visited: Set<Int> = [0]
        while visited.count < pins.count {
            let last = chain.last!
            let next = distances[last].enumerated()
                .sorted { $0.element < $1.element }
                .filter { !visited.contains($0.offset) }
                .first!
                .offset
            chain.append(next)
            visited.insert(next)
        }
        return chain.map { pins[$0] }
    }
}
