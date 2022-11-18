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
    case friends, everyone, me, savedPosts, custom, none
}

struct CurrentMapRequest {
    var requestId: UUID
    var mapLoadStrategy: MapLoadStrategy
    var region: Region
    var categories: [String]
    var users: [String]
}

class MapViewModelV2: ObservableObject {
    var appState: AppState!
    var viewState: GlobalViewState!
    var regionWrapper: RegionWrapper!
    
    private var cancelBag: Set<AnyCancellable> = .init()
    
    private var latestMapRequestId: UUID?
    
    // Used when loading the map from the server
    @Published private(set) var mapLoadStatus: MapLoadStatus = .loading
    
    // Request parameters
    @Published var mapLoadStrategy: MapLoadStrategy = .friends
    @Published var regionToLoad: Region?
    @Published var selectedCategories: Set<Category> = Set(Categories.categories)
    @Published var customUserFilter: Set<UserId> = Set() // Only matters when mapLoadStrategy == .custom
    
    // If this is non-nil, the quick view is visible
    @Published var selectedPin: MKJimoPinAnnotation?
    
    @Published var pins: [MKJimoPinAnnotation] = []
    
    // MARK: - Map actions
    
    func initialize(appState: AppState, viewState: GlobalViewState, regionWrapper: RegionWrapper) {
        self.appState = appState
        self.viewState = viewState
        self.regionWrapper = regionWrapper
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
        Publishers.CombineLatest4($mapLoadStrategy, $regionToLoad, $selectedCategories, $customUserFilter)
            .throttle(for: 0.25, scheduler: RunLoop.main, latest: true)
            .sink { [weak self] mapLoadStrategy, region, categories, users in
                guard let self = self, let region = region, self.selectedPin == nil else {
                    return
                }
                let request = CurrentMapRequest(
                    requestId: UUID(),
                    mapLoadStrategy: mapLoadStrategy,
                    region: region,
                    categories: categories.map(\.key),
                    users: mapLoadStrategy == .me ? [appState.me!.id] : Array(users)
                )
                print("Created request with ID", request.requestId)
                self.loadMap(request: request)
            }
            .store(in: &cancelBag)
        
    }
    
    func isSelected(userId: UserId) -> Bool {
        return customUserFilter.contains(userId)
    }
    
    func selectPin(pin: MKJimoPinAnnotation) {
        let oldValue = selectedPin
        selectedPin = pin // since selectedPin != nil, other areas of the code won't update self.pins
        if oldValue == nil {
            print("Computing quick view path")
            pins = greedyTravelingSalesman(pins: pins)
        }
        regionWrapper.region.center.wrappedValue = pin.coordinate
        if regionWrapper.region.span.longitudeDelta.wrappedValue > 0.2 {
            regionWrapper.region.span.wrappedValue = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        }
        regionWrapper.trigger.toggle()
    }
    
    func selectPin(index: Int) {
        if index < pins.count {
            selectedPin = pins[index]
        }
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
    
    func loadMap(request: CurrentMapRequest) {
        guard let appState = appState, let viewState = viewState else {
            return
        }
        self.latestMapRequestId = request.requestId
        switch mapLoadStrategy {
        case .everyone:
            self.loadGlobalMap(appState: appState, globalViewState: viewState, request: request)
        case .friends:
            self.loadFollowingMap(appState: appState, globalViewState: viewState, request: request)
        case .savedPosts:
            self.loadSavedPostsMap(appState: appState, globalViewState: viewState, request: request)
        case .custom:
            self.loadCustomMap(appState: appState, globalViewState: viewState, request: request)
        case .me:
            // Same as custom, makes it easier to special case
            self.loadCustomMap(appState: appState, globalViewState: viewState, request: request)
        case .none:
            return
        }
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
                self.updateMapPinsAsync(mapResponseV3.pins, request: request)
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
                self.updateMapPinsAsync(mapResponseV3.pins, request: request)
            }.store(in: &cancelBag)
    }
    
    private func loadSavedPostsMap(appState: AppState, globalViewState: GlobalViewState, request: CurrentMapRequest) {
        mapLoadStatus = .loading
        appState.getSavedPostsMap(region: request.region, categories: request.categories)
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
                self.updateMapPinsAsync(mapResponseV3.pins, request: request)
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
                self.updateMapPinsAsync(mapResponseV3.pins, request: request)
            }.store(in: &cancelBag)
    }
    
    ///
    
    func sortUsersHelper(_ user1: PublicUser, _ user2: PublicUser) -> Bool {
        user1.username.caseInsensitiveCompare(user2.username) == .orderedAscending
    }
    
    /// Handle data updates
    
    private func updateMapPinsAsync(_ pins: [MapPinV3], request: CurrentMapRequest) {
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                guard self.selectedPin == nil else {
                    print("Quick view is shown, not updating pins")
                    return
                }
                // TODO: could be more efficient
                if self.latestMapRequestId == request.requestId {
                    let newPins = Set(pins.map({ MKJimoPinAnnotation(from: $0) }))
                    let oldPins = Set(self.pins)
                    self.pins.removeAll(where: { !newPins.contains($0) })
                    self.pins.append(contentsOf: newPins.subtracting(oldPins))
                    self.latestMapRequestId = nil
                } else {
                    print("Request changed, not setting pins")
                }
            }
        }
    }
}


fileprivate func greedyTravelingSalesman(pins: [MKJimoPinAnnotation]) -> [MKJimoPinAnnotation] {
    // Return the list of pins in a somewhat reasonable order
    guard pins.count > 0 else {
        return []
    }
    // Get distance between every point, first int must be < second
    var distances: [[Double]] = [[Double]](repeating: [Double](repeating: -1, count: pins.count), count: pins.count)
    for i in 0..<pins.count-1 {
        for j in i+1..<pins.count {
            let iLocation = MKMapPoint(pins[i].coordinate)
            let jLocation = MKMapPoint(pins[j].coordinate)
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
