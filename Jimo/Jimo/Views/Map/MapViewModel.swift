//
//  MapViewModel.swift
//  Jimo
//
//  Created by admin on 12/27/22.
//

import SwiftUI
import Combine
import MapKit

struct MapRequestState: Equatable, Hashable {
    var requestId: UUID
    var region: RectangularRegion
    var categories: Set<Category>
    var mapType: MapType
    var userIds: Set<UserId>
}

typealias OnMapLoadCallback = (_ numPins: Int) -> ()

struct RegionCache: Codable, Equatable, Hashable {
    // We store both because converting between the two region formats
    // is non-trivial.
    
    var rectangularRegion: RectangularRegion
    var mkCoordinateRegion: MKCoordinateRegion
}

class RegionWrapperV2: ObservableObject {
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
    
    /// This is set by us, we periodically check visibleMapRect and once it's stable (meaning the map has stopped moving we set this)
    @Published var regionToLoad: RectangularRegion?
    
    func setRegion(_ region: MKCoordinateRegion) {
        self._mkCoordinateRegion = region
        self.trigger.toggle()
    }
}

class MapViewModel: RegionWrapperV2 {
    private var postListener = PostListener()
    private var cancelBag: Set<AnyCancellable> = Set()
    private var mapLoadCancellable: AnyCancellable? // One cancellable so we cancel when we re-assign
    
    /// Request types
    @Published var categories: Set<Category> = Set(Categories.categories)
    @Published var mapType: MapType = .following
    @Published var userIds: Set<UserId> = Set()
    @Published var pins: [MKJimoPinAnnotation] = []
    
    /// selectedPin is set when you tap on a pin on the map
    @Published var selectedPin: MKJimoPinAnnotation?
    /// displayedPlaceDetails is set when you tap on a pin or select a search result
    @Published var displayedPlaceDetails: MapPlaceResult?
    @Published var isLoading = false
    
    private var latestMapRequest: MapRequestState?
    
    var initializedFromCache: Bool
    
    override init() {
        self.initializedFromCache = false
        super.init()
        if let data = UserDefaults.standard.object(forKey: "mapRegion") as? Data,
           let cache = try? JSONDecoder().decode(RegionCache.self, from: data) {
            self.regionToLoad = cache.rectangularRegion
            self._mkCoordinateRegion = cache.mkCoordinateRegion
        }
    }
    
    func initializeMap(appState: AppState, viewState: GlobalViewState, onLoad: @escaping OnMapLoadCallback) {
        if initializedFromCache && self.regionToLoad != nil {
            self.loadMap(appState: appState, viewState: viewState, onLoad: { [weak self] numPins in
                onLoad(numPins)
                self?.listenToRegionChanges(appState: appState, viewState: viewState)
            })
        } else {
            if let location = PermissionManager.shared.getLocation() {
                self.setRegion(
                    MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                )
            }
            self.listenToRegionChanges(appState: appState, viewState: viewState)
        }
        postListener.onPostCreated = { post in
            DispatchQueue.main.async {
                self.loadMap(appState: appState, viewState: viewState, onLoad: {_ in})
                if self.displayedPlaceDetails?.place?.placeId == post.place.placeId {
                    self.displayedPlaceDetails?.details?.followingPosts.insert(post, at: 0)
                }
            }
        }
        postListener.onPostDeleted = { postId in
            DispatchQueue.main.async {
                self.loadMap(appState: appState, viewState: viewState, onLoad: {_ in})
                // Current user's posts will be in following posts so we only have to remove from there
                self.displayedPlaceDetails?.details?.followingPosts.removeAll(where: { $0.postId == postId })
            }
        }
    }
    
    func listenToRegionChanges(appState: AppState, viewState: GlobalViewState) {
        var previouslyLoadedRegion: RectangularRegion?
        var previousRegion: RectangularRegion?
        Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self = self else {
                    return
                }
                guard let region = self.visibleMapRect else {
                    return
                }
                if region == previousRegion && region != previouslyLoadedRegion {
                    print("Region changed, updating regionToLoad")
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
                    requestId: UUID(),
                    region: region,
                    categories: categories,
                    mapType: mapType,
                    userIds: userIds
                )
                print("Created request with ID", request.requestId, mapType)
                self.loadMap(request, appState: appState, viewState: viewState, onLoad: nil)
            }
            .store(in: &cancelBag)
    }
    
    func selectPin(
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
        guard let placeId = pin.placeId else {
            viewState.setError("Cannot load place details")
            return
        }
        var center = pin.coordinate
        center.latitude -= 0.0015
        self.setRegion(MKCoordinateRegion(center: center, span: .init(latitudeDelta: 0.005, longitudeDelta: 0.005)))
        if let details = displayedPlaceDetails, details.place?.placeId == selectedPin?.placeId {
            // Just use the last-loaded place details
            displayedPlaceDetails?.isStale = false
            return
        }
        appState.getPlaceDetails(placeId: placeId)
            .sink { completion in
                if case let .failure(error) = completion {
                    print("Error when getting place details", error)
                    viewState.setError("Could not load place details")
                }
            } receiveValue: { [weak self] placeDetails in
                self?.displayedPlaceDetails = MapPlaceResult(details: placeDetails)
                self?.loadMapItemForPlaceDetails()
            }
            .store(in: &cancelBag)
    }
    
    func selectSearchResult(
        appState: AppState,
        viewState: GlobalViewState,
        mapItem: MKMapItem
    ) {
        self.displayedPlaceDetails = MapPlaceResult(mkMapItem: mapItem)
        guard let placeName = mapItem.placemark.name else {
            return
        }
        var center = mapItem.placemark.coordinate
        center.latitude -= 0.0015
        self.setRegion(MKCoordinateRegion(center: center, span: .init(latitudeDelta: 0.005, longitudeDelta: 0.005)))
        appState.findPlace(
            name: placeName,
            latitude: mapItem.placemark.coordinate.latitude,
            longitude: mapItem.placemark.coordinate.longitude
        ).flatMap { response in
            guard let place = response.place else {
                // TODO kind of hacky
                let fakePlace = Place(
                    placeId: "",
                    name: mapItem.placemark.name ?? "",
                    location: Location(coord: mapItem.placemark.coordinate)
                )
                self.selectPinIfExistsFakeIt(fakePlace)
                return Just<GetPlaceDetailsResponse?>(nil)
                    .setFailureType(to: APIError.self)
                    .eraseToAnyPublisher()
            }
            self.selectPinIfExistsFakeIt(place)
            return appState.getPlaceDetails(placeId: place.id)
                .map { (response: GetPlaceDetailsResponse) in (response as GetPlaceDetailsResponse?) }
                .eraseToAnyPublisher()
        }.sink { completion in
            if case let .failure(error) = completion {
                print("Error when getting place details", error)
                viewState.setError("Could not load place details")
            }
        } receiveValue: { [weak self] placeDetails in
            print("setting map search result")
            self?.displayedPlaceDetails = MapPlaceResult(
                mkMapItem: mapItem,
                details: placeDetails
            )
        }
        .store(in: &cancelBag)
    }
    
    private func loadMapItemForPlaceDetails() {
        guard let place = displayedPlaceDetails?.place else {
            return
        }
        let location = CLLocation(latitude: place.location.latitude, longitude: place.location.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { response, error in
            if let response = response, let placemark = response.first {
                // Got the CLPlacemark, now try to get the MKMapItem to get the business details
                let searchRequest = MKLocalSearch.Request()
                searchRequest.region = .init(center: place.location.coordinate(), span: .init(latitudeDelta: 0, longitudeDelta: 0))
                searchRequest.naturalLanguageQuery = place.name
                MKLocalSearch(request: searchRequest).start { (response, error) in
                    if let response = response {
                        for mapItem in response.mapItems {
                            if let placemarkLocation = placemark.location,
                               let mapItemLocation = mapItem.placemark.location,
                               mapItemLocation.distance(from: placemarkLocation) < 10 {
                                self.displayedPlaceDetails?.mkMapItem = mapItem
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func selectPinIfExistsFakeIt(_ place: Place) {
        if let pin = self.pins.first(where: { $0.placeId == place.placeId }) {
            self.selectedPin = pin
            var center = pin.coordinate
            center.latitude -= 0.0015
            self._mkCoordinateRegion.center = center
            self.trigger.toggle()
        } else {
            let pin = MKJimoPinAnnotation(coordinate: place.location.coordinate())
            pin.placeId = place.placeId
            self.pins.append(pin)
            self.selectedPin = pin
        }
    }
    
    private func loadMap(appState: AppState, viewState: GlobalViewState, onLoad: OnMapLoadCallback?) {
        guard let region = self.regionToLoad else {
            print("no region to load")
            return
        }
        self.loadMap(
            MapRequestState(
                requestId: UUID(),
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
                print(err)
                //viewState.setError("Could not load map")
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
                    self.selectedPin = replacement
                } else {
                    self.pins.append(selectedPin)
                }
            }
            onLoad?(self.pins.count)
        }
    }
}

struct MapPlaceResult: Equatable {
    var isStale = false
    /// Apple maps MapKit item
    var mkMapItem: MKMapItem?
    
    /// Jimo place details
    var details: GetPlaceDetailsResponse?
    
    var place: Place? {
        details?.place
    }
    
    var name: String {
        place?.name ?? mkMapItem?.name ?? ""
    }
    
    var latitude: Double {
        place?.location.latitude ?? mkMapItem?.placemark.coordinate.latitude ?? 0
    }
    
    var longitude: Double {
        place?.location.longitude ?? mkMapItem?.placemark.coordinate.longitude ?? 0
    }
    
    var communityPosts: [Post] {
        details?.communityPosts ?? []
    }
    
    var featuredPosts: [Post] {
        details?.featuredPosts ?? []
    }
    
    var followingPosts: [Post] {
        details?.followingPosts ?? []
    }
    
    var address: String {
        guard let mkMapItem = mkMapItem else {
            return ""
        }
        let placemark = mkMapItem.placemark
        var streetAddress: String? = nil
        if let subThoroughfare = placemark.subThoroughfare,
           let thoroughfare = placemark.thoroughfare {
            streetAddress = subThoroughfare + " " + thoroughfare
        }
        let components = [
            streetAddress,
            placemark.locality,
            placemark.administrativeArea
        ];
        return components.compactMap({ $0 }).joined(separator: ", ")
    }
}

extension MKMapView {
    func rectangularRegion() -> RectangularRegion {
        let rect = self.convert(self.region, toRectTo: self)
        let bl = self.convert(CGPoint(x: rect.minX, y: rect.minY), toCoordinateFrom: self)
        let tr = self.convert(CGPoint(x: rect.maxX, y: rect.maxY), toCoordinateFrom: self)
        return RectangularRegion(
            xMin: bl.longitude,
            yMin: bl.latitude,
            xMax: tr.longitude,
            yMax: tr.latitude
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
            center: .init(latitude: centerLat, longitude:  centerLong),
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

class PostListener {
    typealias OnPostCreated = (Post) -> ()
    typealias OnPostDeleted = (PostId) -> ()
    
    let nc = NotificationCenter.default
    
    var onPostCreated: OnPostCreated?
    var onPostDeleted: OnPostDeleted?
    
    init() {
        nc.addObserver(self, selector: #selector(postCreated), name: PostPublisher.postCreated, object: nil)
        nc.addObserver(self, selector: #selector(postDeleted), name: PostPublisher.postDeleted, object: nil)
    }
    
    @objc private func postCreated(notification: Notification) {
        let post = notification.object as! Post
        onPostCreated?(post)
    }
    
    @objc private func postDeleted(notification: Notification) {
        let postId = notification.object as! PostId
        onPostDeleted?(postId)
    }
}
