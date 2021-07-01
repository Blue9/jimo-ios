//
//  MapViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/28/21.
//

import SwiftUI
import MapKit
import Combine

class MapViewModel: ObservableObject {
    static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.13284, longitude: -95.78558),
        span: MKCoordinateSpan(latitudeDelta: 85.762482, longitudeDelta: 61.276015))
    
    let appState: AppState
    let globalViewState: GlobalViewState
    let preselectedPost: Post? // If we are navigating to the map from a post
    
    /// When first launching the map, if preselectedPost != nil we want to open the bottom sheet for it.
    /// This lets us know whether we have done that or not so we don't repeatedly open the bottom sheet.
    var displayedInitialBottomSheetForPresentedPost: Bool = false
    
    var mapRefreshCancellable: Cancellable? = nil
    var annotationsCancellable: Cancellable? = nil
    var loadPreselectedPost: Cancellable?
    
    @Published var presentedPin: PlaceAnnotation? {
        didSet {
            if presentedPin != nil {
                modalState = .large
            }
        }
    }
    @Published var results: [MKMapItem]? {
        didSet {
            if results != nil {
                modalState = .large
            }
        }
    }
    @Published var selectedSearchResult: MKMapItem?
    @Published var modalState: OvercastSnapState = .invisible {
        didSet {
            if modalState == .invisible {
                presentedPin = nil
                results = nil
                selectedSearchResult = nil
            }
        }
    }
    @Published var mapAnnotations: [PlaceAnnotation] = []
    
    var showSearchBar: Bool {
        preselectedPost == nil
    }
    
    init(appState: AppState, viewState: GlobalViewState, preselectedPost: Post? = nil) {
        self.appState = appState
        self.globalViewState = viewState
        self.preselectedPost = preselectedPost
    }
    
    func startRefreshingMap() {
        print("Starting map refresh")
        mapRefreshCancellable = Deferred { Just(Date()) }
            .append(Timer.publish(every: 120, tolerance: 5, on: .main, in: .common).autoconnect())
            .flatMap { [weak self] _ -> AnyPublisher<Void, Never> in
                guard let self = self else {
                    return Empty().eraseToAnyPublisher()
                }
                return self.refreshMap()
            }
            .sink {}
        if let post = preselectedPost {
            loadPreselectedPost = appState.loadPlaceIcon(for: post.place)
                .sink { [weak self] completion in
                    if case let .failure(error) = completion {
                        print("Error loading place", error)
                        self?.globalViewState.setError("Failed to load place details")
                    }
                } receiveValue: { _ in }
        }
        annotationsCancellable = appState.mapModel.$places
            .sink { [weak self] pins in
                // Handle preselected post
                self?.updateAnnotations(pins: pins)
            }
    }
    
    func refreshMap() -> AnyPublisher<Void, Never> {
        self.appState.refreshMap()
            .catch { error -> AnyPublisher<Void, Never> in
                print("Error when getting map", error)
                return Just(()).eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
    
    func stopRefreshingMap() {
        print("Stopped refreshing map")
        mapRefreshCancellable?.cancel()
    }
    
    func updateAnnotations(pins: [MapPlace]) {
        var newPins = pins
        // If we are presenting a pin then don't remove it even if it's not in pins
        if let presentedPin = presentedPin,
           !newPins.map({ $0.place.placeId }).contains(presentedPin.pin.place.placeId)
        {
            newPins.append(presentedPin.pin)
        }
        newPins.sort(by: { place1, place2 in
            return place1.icon.numMutualPosts < place2.icon.numMutualPosts
        })
        mapAnnotations = newPins.enumerated().map({ (i, pin) in
            return PlaceAnnotation(pin: pin, zIndex: i)
        })
        // Handle preselected post
        if let post = preselectedPost,
           !displayedInitialBottomSheetForPresentedPost,
           let annotation = mapAnnotations.first(where: { $0.pin.place.placeId == post.place.placeId })
        {
            presentedPin = annotation
            modalState = .tiny
            displayedInitialBottomSheetForPresentedPost = true
        }
    }
}


class PlaceAnnotation: NSObject, MKAnnotation {
    let pin: MapPlace
    let zIndex: Int
    
    var coordinate: CLLocationCoordinate2D {
        let coordinate = pin.place.location.coordinate()
        if coordinate.latitude == 0 && coordinate.longitude == 0 {
            // For some reason annotations at exactly (0, 0) don't appear on the map
            return .init(latitude: Double.leastNormalMagnitude, longitude: Double.leastNormalMagnitude)
        } else {
            return coordinate
        }
    }
    
    init(pin: MapPlace, zIndex: Int) {
        self.pin = pin
        self.zIndex = zIndex
    }
    
    var place: Place {
        pin.place
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let placeAnnotation = object as? PlaceAnnotation {
            return pin == placeAnnotation.pin
        }
        return false
    }
    
    override var hash: Int {
        return coordinate.latitude.hashValue ^ coordinate.longitude.hashValue
    }
}
