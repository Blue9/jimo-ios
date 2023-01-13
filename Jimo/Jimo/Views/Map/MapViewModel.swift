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

class MapViewModel: RegionWrapper {
    private var cancelBag: Set<AnyCancellable> = Set()
    private var mapLoadCancellable: AnyCancellable? // One cancellable so we cancel when we re-assign
    
    /// Request types
    @Published var regionToLoad: RectangularRegion?
    @Published var categories: Set<Category> = Set(Categories.categories)
    @Published var mapType: MapType = .following
    @Published var userIds: Set<UserId> = Set()
    @Published var pins: [MKJimoPinAnnotation] = []
    
    /// selectedPin is set when you tap on a pin on the map
    @Published var selectedPin: MKJimoPinAnnotation?
    /// displayedPlaceDetails is set when you tap on a pin or select a search result
    @Published var displayedPlaceDetails: MapPlaceResult?
    
    private var latestMapRequest: MapRequestState?
    
    override init() {
        super.init()
        if let data = UserDefaults.standard.object(forKey: "mapRegion") as? Data,
           let region = try? JSONDecoder().decode(RectangularRegion.self, from: data) {
            self.regionToLoad = region
            self._region.center = region.center.coordinate()
            self._region.span.latitudeDelta = region.latitudeDeltaDegrees
            self._region.span.longitudeDelta = region.longitudeDeltaDegrees
        }
    }
    
    func initializeMap(appState: AppState, viewState: GlobalViewState, onLoad: @escaping OnMapLoadCallback) {
        if self.regionToLoad == nil, let location = PermissionManager.shared.getLocation() {
            self.setRegion(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        } else if self.regionToLoad != nil {
            self.loadMap(appState: appState, viewState: viewState, onLoad: { [weak self] numPins in
                onLoad(numPins)
                self?.listenToRegionChanges(appState: appState, viewState: viewState)
            })
        }
    }
    
    func listenToRegionChanges(appState: AppState, viewState: GlobalViewState) {
        var previouslyLoadedRegion: MKCoordinateRegion?
        var previousRegion: MKCoordinateRegion?
        Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self = self else {
                    return
                }
                let region = self._region
                if region == previousRegion && region != previouslyLoadedRegion {
                    print("Region changed, updating regionToLoad")
                    self.regionToLoad = RectangularRegion(
                        center: Location(coord: region.center),
                        longitudeDeltaDegrees: region.span.longitudeDelta,
                        latitudeDeltaDegrees: region.span.latitudeDelta
                    )
                    if let data = try? JSONEncoder().encode(self.regionToLoad) {
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
                return Just(GetPlaceDetailsResponse(
                    place: Place(
                        placeId: "",
                        name: placeName,
                        location: Location(coord: mapItem.placemark.coordinate)),
                    communityPosts: [],
                    featuredPosts: [],
                    followingPosts: []
                ))
                .setFailureType(to: APIError.self)
                .eraseToAnyPublisher()
            }
            self.selectPinIfExistsFakeIt(place)
            return appState.getPlaceDetails(placeId: place.id)
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
            self._region.center = center
            self.trigger.toggle()
        } else {
            let pin = MKJimoPinAnnotation(coordinate: place.location.coordinate())
            pin.placeId = place.placeId
            self.pins.append(pin)
            self.selectedPin = pin
        }
    }
    
    private func loadMap(appState: AppState, viewState: GlobalViewState, onLoad: OnMapLoadCallback?) {
        self.loadMap(
            MapRequestState(
                requestId: UUID(),
                region: RectangularRegion(
                    center: Location(coord: _region.center),
                    longitudeDeltaDegrees: _region.span.longitudeDelta,
                    latitudeDeltaDegrees: _region.span.latitudeDelta
                ),
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
        self.latestMapRequest = request
        // Note that re-assigning this cancels previous requests so we always use the latest request
        mapLoadCancellable = appState.getMap(
            region: request.region,
            categories: request.categories.map { $0.key },
            mapType: request.mapType,
            userIds: Array(request.userIds)
        ).sink { completion in
            if case let .failure(err) = completion {
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
