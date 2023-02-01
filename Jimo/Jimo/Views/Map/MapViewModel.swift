//
//  MapViewModel.swift
//  Jimo
//
//  Created by admin on 12/27/22.
//

import SwiftUI
import Combine
import MapKit
import FirebaseRemoteConfig

struct MapRequestState: Equatable, Hashable {
    var region: RectangularRegion
    var categories: Set<Category>
    var mapType: MapType
    var userIds: Set<UserId>
}

typealias OnMapLoadCallback = (_ numPins: Int) -> Void

struct RegionCache: Codable, Equatable, Hashable {
    // We store both because converting between the two region formats
    // is non-trivial.

    var rectangularRegion: RectangularRegion
    var mkCoordinateRegion: MKCoordinateRegion
}

class MapViewModel: ObservableObject {
    // MARK: - RegionWrapper
    // This used to be `class RegionWrapper: ObservableObject` and MapViewModel extended it,
    // but that was leading to crashes (https://developer.apple.com/forums/thread/722650),
    // so now it's part of the class.
    /// Used internally by MapKit. When we change this, JimoMapView will call updateUIView and update the region.
    /// It will then call the regionDidChange delegate method which updates visibleMapRect.
    var _mkCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37, longitude: -96),
        span: MKCoordinateSpan(latitudeDelta: 85, longitudeDelta: 61))
    var mkCoordinateRegion: Binding<MKCoordinateRegion> {
        Binding(
            get: { self._mkCoordinateRegion },
            set: { self._mkCoordinateRegion = $0 }
        )
    }
    @Published var trigger = false

    /// This is set by JimoMapView whenever the map region completes changing (in the didChange delegate method)
    var visibleMapRect: RectangularRegion?

    /// This is set by us, we periodically check visibleMapRect
    /// and once it's stable (meaning the map has stopped moving we set this)
    @Published var regionToLoad: RectangularRegion?

    func setRegion(_ region: MKCoordinateRegion) {
        self._mkCoordinateRegion = region
        self.trigger.toggle()
    }

    // MARK: - Actual MapViewModel

    private var cancelBag: Set<AnyCancellable> = Set()
    private var mapLoadCancellable: AnyCancellable? // One cancellable so we cancel when we re-assign

    /// Request types
    @Published var categories: Set<Category> = Set(Categories.categories)
    @Published var mapType: MapType = .following
    @Published var userIds: Set<UserId> = Set()
    @Published var pins: [MKJimoPinAnnotation] = []

    /// selectedPin is set when you tap on a pin on the map
    @Published var selectedPin: MKJimoPinAnnotation?
    @Published var isLoading = false

    private var latestMapRequest: MapRequestState?

    var initializedFromCache: Bool

    init() {
        self.initializedFromCache = false
        // Only want initialize from cache if we don't have the user's location
        // If we do have their location we want to open to their location
        if let location = PermissionManager.shared.getLocation() {
            self._mkCoordinateRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            // This isn't entirely accurate since we don't have the actual map rect available
            // but it's close enough
            self.regionToLoad = .init(
                xMin: location.coordinate.longitude - 0.025,
                yMin: location.coordinate.latitude - 0.025,
                xMax: location.coordinate.longitude + 0.025,
                yMax: location.coordinate.latitude + 0.025
            )
        } else if let data = UserDefaults.standard.object(forKey: "mapRegion") as? Data,
           let cache = try? JSONDecoder().decode(RegionCache.self, from: data) {
            self.regionToLoad = cache.rectangularRegion
            self._mkCoordinateRegion = cache.mkCoordinateRegion
            self.initializedFromCache = true
        }
    }

    func initializeMap(appState: AppState, viewState: GlobalViewState, onLoad: @escaping OnMapLoadCallback) {
        if appState.me == nil {
            // Anonymous user
            self.mapType = .custom
            if let value = RemoteConfig.remoteConfig().configValue(forKey: "featuredUsersForGuestMap").jsonValue,
               let parsed = value as? [[String: String]] {
                self.userIds = Set(parsed.compactMap(\.["userId"]))
            } else {
                viewState.setError("Map is currently unavailable")
                self.userIds = []
            }
        }
        if self.regionToLoad != nil {
            self.loadMap(appState: appState, viewState: viewState, onLoad: { [weak self] numPins in
                onLoad(numPins)
                self?.listenToRegionChanges(appState: appState, viewState: viewState)
            })
        } else {
            self.listenToRegionChanges(appState: appState, viewState: viewState)
        }
    }

    func listenToRegionChanges(appState: AppState, viewState: GlobalViewState) {
        var previouslyLoadedRegion: RectangularRegion?
        var previousRegion: RectangularRegion?
        Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self = self else {
                    return
                }
                guard let region = self.visibleMapRect else {
                    return
                }
                if region == previousRegion && region != previouslyLoadedRegion {
                    print("Region changed, updating regionToLoad \(previouslyLoadedRegion) to \(previousRegion)")
                    self.regionToLoad = region
                    if let data = try? JSONEncoder().encode(RegionCache(rectangularRegion: region, mkCoordinateRegion: self._mkCoordinateRegion)) {
                        UserDefaults.standard.set(data, forKey: "mapRegion")
                    }
                    previouslyLoadedRegion = region
                }
                previousRegion = region
            }
            .store(in: &cancelBag)
        // This continuously loads the map as the filters change
        Publishers.CombineLatest4($regionToLoad, $categories, $mapType, $userIds)
            .throttle(for: 0.25, scheduler: RunLoop.main, latest: true)
            .sink { [weak self] region, categories, mapType, userIds in
                guard let self = self, let region = region else {
                    return
                }
                let request = MapRequestState(
                    region: region,
                    categories: categories,
                    mapType: mapType,
                    userIds: userIds
                )
                guard request != self.latestMapRequest else {
                    print("Duplicate request ignoring")
                    return
                }
                print("Created request with hash", request.hashValue, mapType)
                self.loadMap(request, appState: appState, viewState: viewState, onLoad: nil)
            }
            .store(in: &cancelBag)
    }

    func selectPin(
        placeViewModel: PlaceDetailsViewModel,
        appState: AppState,
        viewState: GlobalViewState,
        pin: MKJimoPinAnnotation?
    ) {
        if self.selectedPin == pin {
            return
        }
        self.selectedPin = pin
        guard let pin = pin else {
            return
        }
        // Move map to pin
        var center = pin.coordinate
        center.latitude -= self._mkCoordinateRegion.span.latitudeDelta * 0.25
        self.setRegion(MKCoordinateRegion(center: center, span: self._mkCoordinateRegion.span))
        placeViewModel.selectPlace(pin.placeId, appState: appState, viewState: viewState)
    }

    func selectSearchResult(
        placeViewModel: PlaceDetailsViewModel,
        appState: AppState,
        viewState: GlobalViewState,
        mapItem: MKMapItem
    ) {
        placeViewModel.selectMapItem(mapItem, appState: appState, viewState: viewState) { (placeId, coord) in
            self.selectPinIfExistsFakeIt(placeId: placeId, coordinate: coord)
            var center = mapItem.placemark.coordinate
            center.latitude -= 0.0015
            self.setRegion(
                MKCoordinateRegion(
                    center: center,
                    span: .init(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )
        }
    }

    private func selectPinIfExistsFakeIt(placeId: PlaceId?, coordinate: CLLocationCoordinate2D) {
        guard let placeId = placeId, let pin = self.pins.first(where: { $0.placeId == placeId }) else {
            let pin = MKJimoPinAnnotation(coordinate: coordinate)
            pin.placeId = placeId
            self.pins.append(pin)
            self.selectedPin = pin
            return
        }
        self.selectedPin = pin
        var center = pin.coordinate
        center.latitude -= 0.0015
        self._mkCoordinateRegion.center = center
        self.trigger.toggle()
    }

    private func loadMap(appState: AppState, viewState: GlobalViewState, onLoad: OnMapLoadCallback?) {
        guard let region = self.regionToLoad else {
            print("no region to load")
            return
        }
        self.loadMap(
            MapRequestState(
                region: region,
                categories: categories,
                mapType: mapType,
                userIds: userIds
            ),
            appState: appState,
            viewState: viewState,
            onLoad: onLoad
        )
    }

    private func loadMap(_ request: MapRequestState, appState: AppState, viewState: GlobalViewState, onLoad: OnMapLoadCallback?) {
        self.isLoading = true
        self.latestMapRequest = request
        // Note that re-assigning this cancels previous requests so we always use the latest request
        mapLoadCancellable = appState.getMap(
            region: request.region,
            categories: request.categories.map { $0.key },
            mapType: request.mapType,
            userIds: Array(request.userIds)
        ).sink { completion in
            self.isLoading = false
            if case let .failure(err) = completion {
                onLoad?(0)
                print(err)
                // viewState.setError("Could not load map")
            }
        } receiveValue: { response in
            // Instead of a simple self.pins = response.pins.map(...)
            // We diff the response with the current set of pins. This is because
            // MapKit's internal representation of annotations uses memory addresses,
            // but because isEquals is implemented for MKJimoPinAnnotation, it seems to
            // end up in some sort of an inconsistent state.
            let newPins = Set(response.pins.map({ MKJimoPinAnnotation(from: $0) }))
            let oldPins = Set(self.pins)
            self.pins.removeAll(where: { !newPins.contains($0) })
            self.pins.append(contentsOf: newPins.subtracting(oldPins))
            if let selectedPin = self.selectedPin {
                if let replacement = self.pins.first(where: { $0.placeId == selectedPin.placeId }),
                   self.selectedPin != replacement {
                    // TODO when we do this this causes the bottom sheet to be displayed again because
                    // updateUIView selects the annotation again.
                    self.selectedPin = replacement
                } else {
                    self.pins.append(selectedPin)
                }
            }
            onLoad?(self.pins.count)
        }
    }
}

extension MKMapView {
    func rectangularRegion() -> RectangularRegion {
        let rect = self.convert(self.region, toRectTo: self)
        let tl = self.convert(CGPoint(x: rect.minX, y: rect.minY), toCoordinateFrom: self)
        let br = self.convert(CGPoint(x: rect.maxX, y: rect.maxY), toCoordinateFrom: self)
        return RectangularRegion(
            xMin: tl.longitude,
            yMin: br.latitude,
            xMax: br.longitude,
            yMax: tl.latitude
        )
    }
}

extension MKCoordinateRegion: Codable {
    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(self.center.latitude, forKey: .centerLat)
        try values.encode(self.center.longitude, forKey: .centerLong)
        try values.encode(self.span.latitudeDelta, forKey: .latSpan)
        try values.encode(self.span.longitudeDelta, forKey: .longSpan)
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let centerLat = try values.decode(Double.self, forKey: .centerLat)
        let centerLong = try values.decode(Double.self, forKey: .centerLong)

        let longSpan = try values.decode(Double.self, forKey: .longSpan)
        let latSpan = try values.decode(Double.self, forKey: .latSpan)
        self.init(
            center: .init(latitude: centerLat, longitude: centerLong),
            span: .init(latitudeDelta: latSpan, longitudeDelta: longSpan)
        )
    }

    enum CodingKeys: String, CodingKey {
        case centerLat
        case centerLong
        case longSpan
        case latSpan
    }
}

class PostPlaceListener {
    typealias OnPostCreated = (Post) -> Void
    typealias OnPostDeleted = (PostId) -> Void
    typealias OnPlaceSave = (PlaceSavePayload) -> Void

    let nc = NotificationCenter.default

    var onPostCreated: OnPostCreated?
    var onPlaceSave: OnPlaceSave?
    var onPostDeleted: OnPostDeleted?

    init() {
        nc.addObserver(self, selector: #selector(postCreated), name: PostPublisher.postCreated, object: nil)
        nc.addObserver(self, selector: #selector(placeSaved), name: PlacePublisher.placeSaved, object: nil)
        nc.addObserver(self, selector: #selector(postDeleted), name: PostPublisher.postDeleted, object: nil)
    }

    @objc private func postCreated(notification: Notification) {
        let post = notification.object as! Post
        onPostCreated?(post)
    }

    @objc private func placeSaved(notification: Notification) {
        let payload = notification.object as! PlaceSavePayload
        onPlaceSave?(payload)
    }

    @objc private func postDeleted(notification: Notification) {
        let postId = notification.object as! PostId
        onPostDeleted?(postId)
    }
}
