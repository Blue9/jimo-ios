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

enum MapLoadStrategy {
    case everyone, following, custom, none
}

struct CurrentMapRequest {
    var requestId: UUID
    var mapLoadStrategy: MapLoadStrategy
    var region: Region
    var categories: [String]
    var users: [String]
}

protocol MapActions {
    func initialize(appState: AppState, viewState: GlobalViewState, regionWrapper: RegionWrapper)
    
    func toggleGlobal()
    func toggleFollowing()
    func toggleUser(user: PublicUser)
    
    var globalSelected: Bool { get }
    var followingSelected: Bool { get }
    func isSelected(userId: UserId) -> Bool
    
    func selectPin(index: Int)
    func deselectPin()
}

class MapViewModelV2: MapActions, ObservableObject {
    var appState: AppState!
    var viewState: GlobalViewState!
    var regionWrapper: RegionWrapper!
    
    private var cancelBag: Set<AnyCancellable> = .init()
    
    private var latestMapRequestId: UUID?
    
    // Used when loading the map from the server
    @Published private(set) var mapLoadStatus: MapLoadStatus = .loading
    
    // Request parameters
    @Published private(set) var mapLoadStrategy: MapLoadStrategy = .following
    @Published var regionToLoad: Region?
    @Published var selectedCategories: Set<String> = [
        "food",
        "activity",
        "nightlife",
        "attraction",
        "lodging",
        "shopping"
    ]
    @Published private(set) var selectedUsers: Set<UserId> = .init()
    
    // If this is non-nil, the quick view is visible
    @Published var selectedPin: MapPinV3?
    
    @Published private(set) var pins: [MapPinV3] = []
    @Published private(set) var userSearchResults: [PublicUser] = []
    
    @Published private(set) var loadedUsers: [UserId: PublicUser] = [:]
    @Published var searchUsersQuery: String = ""
    
    // MARK: - Map actions
    
    var globalSelected: Bool {
        mapLoadStrategy == .everyone
    }
    
    var followingSelected: Bool {
        mapLoadStrategy == .following
    }
    
    func initialize(appState: AppState, viewState: GlobalViewState, regionWrapper: RegionWrapper) {
        guard case let .user(user) = appState.currentUser else {
            return
        }
        self.loadedUsers[user.id] = user
        self.appState = appState
        self.viewState = viewState
        self.regionWrapper = regionWrapper
        self.listenToSearchQuery()
        self.loadFollowing()
        if let location = PermissionManager.shared.getLocation() {
            self.regionWrapper.region.wrappedValue = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            self.regionWrapper.trigger.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.listenToRegionChanges()
            }
        } else {
            self.listenToRegionChanges()
        }
        Publishers.CombineLatest4($mapLoadStrategy, $regionToLoad, $selectedCategories, $selectedUsers)
            .throttle(for: 1, scheduler: RunLoop.main, latest: true)
            .sink { [weak self] mapLoadStrategy, region, categories, users in
                guard let self = self, let region = region, self.selectedPin == nil else {
                    return
                }
                let request = CurrentMapRequest(
                    requestId: UUID(),
                    mapLoadStrategy: mapLoadStrategy,
                    region: region,
                    categories: Array(categories),
                    users: Array(users)
                )
                print("Created request with ID", request.requestId)
                self.loadMap(request: request)
            }
            .store(in: &cancelBag)
        
    }
    
    func toggleGlobal() {
        if mapLoadStrategy != .everyone {
            mapLoadStrategy = .everyone
            selectedUsers.removeAll()
        } else {
            mapLoadStrategy = .none
            pins.removeAll()
        }
    }
    
    func toggleFollowing() {
        if mapLoadStrategy != .following {
            mapLoadStrategy = .following
            selectedUsers.removeAll()
        } else {
            mapLoadStrategy = .none
            pins.removeAll()
        }
    }
    
    func toggleUser(user: PublicUser) {
        self.loadedUsers[user.id] = user
        if mapLoadStrategy != .custom {
            mapLoadStrategy = .custom
            selectedUsers.insert(user.id)
        } else if selectedUsers.contains(user.id) {
            selectedUsers.remove(user.id)
        } else {
            selectedUsers.insert(user.id)
        }
        if selectedUsers.isEmpty {
            pins.removeAll()
        }
    }
    
    func isSelected(userId: UserId) -> Bool {
        return selectedUsers.contains(userId)
    }
    
    func selectPin(index: Int) {
        if index < pins.count {
            selectedPin = pins[index]
        }
    }
    
    func deselectPin() {
        selectedPin = nil
    }
    
    func listenToRegionChanges() {
        guard let regionWrapper = regionWrapper else {
            return
        }
        var previouslyLoadedRegion: MKCoordinateRegion?
        var previousRegion: MKCoordinateRegion?
        Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self = self else {
                    return
                }
                let currentRegion = regionWrapper._region
                if currentRegion == previousRegion && currentRegion != previouslyLoadedRegion {
                    print("Region changed, updating regionToLoad")
                    let region = regionWrapper._region
                    self.regionToLoad = Region(
                        coord: region.center,
                        radius: region.span.longitudeDelta * 111111
                    )
                    previouslyLoadedRegion = currentRegion
                }
                previousRegion = currentRegion
            }
            .store(in: &cancelBag)
    }
    
    func listenToSearchQuery() {
        guard let appState = appState, let viewState = viewState else {
            return
        }
        $searchUsersQuery
            .debounce(for: 0.5, scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.search(appState: appState, globalViewState: viewState, query: query)
            }
            .store(in: &cancelBag)
    }
    
    func loadMap(request: CurrentMapRequest) {
        guard let appState = appState, let viewState = viewState else {
            return
        }
        self.latestMapRequestId = request.requestId
        switch mapLoadStrategy {
        case .everyone:
            self.loadGlobalMap(appState: appState, globalViewState: viewState, request: request)
        case .following:
            self.loadFollowingMap(appState: appState, globalViewState: viewState, request: request)
        case .custom:
            self.loadCustomMap(appState: appState, globalViewState: viewState, request: request)
        case .none:
            return
        }
    }
    
    func loadFollowing() {
        guard let appState = appState, case let .user(user) = appState.currentUser else {
            return
        }
        appState.getFollowing(username: user.username)
            .sink { completion in
                if case let .failure(error) = completion {
                    print("Could not load users", error)
                }
            } receiveValue: { [weak self] response in
                guard let self = self else {
                    return
                }
                let users = response.users.map { $0.user }
                for user in users {
                    self.loadedUsers[user.id] = user
                }
            }.store(in: &cancelBag)
    }
    
    private func loadGlobalMap(appState: AppState, globalViewState: GlobalViewState, request: CurrentMapRequest) {
        mapLoadStatus = .loading
        appState.getGlobalMap(region: request.region, categories: request.categories)
            .sink { [weak self] completion in
                guard let self = self else {
                    return
                }
                if case let .failure(error) = completion {
                    self.mapLoadStatus = .failed
                    print("Error loading map", error)
                    globalViewState.setError("Could not load map")
                } else {
                    self.mapLoadStatus = .success
                }
            } receiveValue: { [weak self] mapResponseV3 in
                guard let self = self else {
                    return
                }
                self.updateMapPinsAsync(mapResponseV3.pins, requestId: request.requestId)
            }.store(in: &cancelBag)
    }
    
    private func loadFollowingMap(appState: AppState, globalViewState: GlobalViewState, request: CurrentMapRequest) {
        mapLoadStatus = .loading
        appState.getFollowingMap(region: request.region, categories: request.categories)
            .sink { [weak self] completion in
                guard let self = self else {
                    return
                }
                if case let .failure(error) = completion {
                    self.mapLoadStatus = .failed
                    print("Error loading map", error)
                    globalViewState.setError("Could not load map")
                } else {
                    self.mapLoadStatus = .success
                }
            } receiveValue: { [weak self] mapResponseV3 in
                guard let self = self else {
                    return
                }
                self.updateMapPinsAsync(mapResponseV3.pins, requestId: request.requestId)
            }.store(in: &cancelBag)
    }
    
    private func loadCustomMap(appState: AppState, globalViewState: GlobalViewState, request: CurrentMapRequest) {
        mapLoadStatus = .loading
        appState.getCustomMap(region: request.region, userIds: request.users, categories: request.categories)
            .sink { [weak self] completion in
                guard let self = self else {
                    return
                }
                if case let .failure(error) = completion {
                    self.mapLoadStatus = .failed
                    print("Error loading map", error)
                    globalViewState.setError("Could not load map")
                } else {
                    self.mapLoadStatus = .success
                }
            } receiveValue: { [weak self] mapResponseV3 in
                guard let self = self else {
                    return
                }
                self.updateMapPinsAsync(mapResponseV3.pins, requestId: request.requestId)
            }.store(in: &cancelBag)
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
    
    ///
    
    func sortUsersHelper(_ user1: PublicUser, _ user2: PublicUser) -> Bool {
        user1.username.caseInsensitiveCompare(user2.username) == .orderedAscending
    }
    
    /// Handle data updates
    
    private func updateMapPinsAsync(_ pins: [MapPinV3], requestId: UUID) {
        DispatchQueue.global(qos: .userInitiated).async {
            let pins = self.greedyTravelingSalesman(pins: pins)
            DispatchQueue.main.async {
                guard self.selectedPin == nil else {
                    print("Quick view is shown, not updating pins")
                    return
                }
                if self.latestMapRequestId == requestId {
                    self.pins = pins
                    self.latestMapRequestId = nil
                } else {
                    print("Request changed, not setting pins")
                }
            }
        }
    }
    
    private func greedyTravelingSalesman(pins: [MapPinV3]) -> [MapPinV3] {
        // Return the list of pins in a somewhat reasonable order
        guard pins.count > 0 else {
            return []
        }
        // Get distance between every point, first int must be < second
        var distances: [[Double]] = [[Double]](repeating: [Double](repeating: -1, count: pins.count), count: pins.count)
        for i in 0..<pins.count-1 {
            for j in i+1..<pins.count {
                let iLocation = MKMapPoint(pins[i].location.coordinate())
                let jLocation = MKMapPoint(pins[j].location.coordinate())
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
