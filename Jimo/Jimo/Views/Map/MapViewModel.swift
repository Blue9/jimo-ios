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

class MapViewModel: RegionWrapper {
    private var cancelBag: Set<AnyCancellable> = Set()
    
    /// Request types
    @Published var regionToLoad: RectangularRegion?
    @Published var categories: Set<Category> = Set(Categories.categories)
    @Published var mapType: MapType = .following
    @Published var userIds: Set<UserId> = Set()
    
    @Published var isLoadingMap = true
    
    @Published var pins: [MKJimoPinAnnotation] = []
    
    /// selectedPin is set when you tap on a pin on the map
    @Published var selectedPin: MKJimoPinAnnotation?
    /// displayedPlaceDetails is set when you tap on a pin or select a search result
    @Published var displayedPlaceDetails: MapPlaceResult?
    
    private var latestMapRequest: MapRequestState?
    
    func initializeMap(appState: AppState, viewState: GlobalViewState) {
        if let location = PermissionManager.shared.getLocation() {
            self.setRegion(
                MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
            self.loadMap(appState: appState, viewState: viewState)
        }
        listenToRegionChanges(appState: appState, viewState: viewState)
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
                    previouslyLoadedRegion = region
                }
                previousRegion = region
            }
            .store(in: &cancelBag)
        // This continuously loads the map as the filters change
        Publishers.CombineLatest4($regionToLoad, $categories, $mapType, $userIds)
            .throttle(for: 0.25, scheduler: RunLoop.main, latest: true)
            .sink { [weak self] region, categories, mapType, userIds in
                guard let self = self, let region = region, !self.isLoadingMap else {
                    return
                }
                let request = MapRequestState(
                    requestId: UUID(),
                    region: region,
                    categories: categories,
                    mapType: mapType,
                    userIds: userIds
                )
                print("Created request with ID", request.requestId)
                self.loadMap(request, appState: appState, viewState: viewState)
            }
            .store(in: &cancelBag)
    }
    
    func selectPin(
        appState: AppState,
        viewState: GlobalViewState,
        pin: MKJimoPinAnnotation
    ) {
        self.selectedPin = pin
        guard let placeId = pin.placeId else {
            viewState.setError("Cannot load place details")
            return
        }
        var center = pin.coordinate
        center.latitude -= 0.002
        self.setRegion(MKCoordinateRegion(center: center, span: region.span.wrappedValue))
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
        self.setRegion(MKCoordinateRegion(center: mapItem.placemark.coordinate, span: region.span.wrappedValue))
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
            self.selectPinIfExists(place.id)
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
    
    private func selectPinIfExists(_ placeId: PlaceId) {
        let matching = self.pins.first(where: { $0.placeId == placeId })
        self.selectedPin = matching
    }
    
    private func loadMap(appState: AppState, viewState: GlobalViewState) {
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
            viewState: viewState
        )
    }
    
    private func loadMap(_ request: MapRequestState, appState: AppState, viewState: GlobalViewState) {
        self.isLoadingMap = true
        self.latestMapRequest = request
        appState.getMap(
            region: request.region,
            categories: request.categories.map { $0.key },
            mapType: request.mapType,
            userIds: Array(request.userIds)
        ).sink { [weak self] completion in
            self?.isLoadingMap = false
            if case .failure = completion {
                viewState.setError("Could not load map")
            }
        } receiveValue: { [weak self] response in
            guard let self = self,
                  self.latestMapRequest?.requestId == request.requestId else {
                print("Mismatched request ID not updating map")
                return
            }
            self.pins = response.pins.map { MKJimoPinAnnotation(from: $0) }
        }.store(in: &cancelBag)
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
