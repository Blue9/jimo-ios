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
    
    /// When first launching the map, if preselectedPost != nil we want to open the bottom sheet for it.
    /// This lets us know whether we have done that or not so we don't repeatedly open the bottom sheet.
    var displayedInitialBottomSheetForPresentedPost: Bool = false
    
    var mapRefreshCancellable: Cancellable?
    var loadPreselectedPlace: Cancellable?
    
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
    
    func startRefreshingMap(appState: AppState, globalViewState: GlobalViewState, preselectedPlace: Place?) {
        print("Starting map refresh")
        mapRefreshCancellable = Deferred { Just(Date()) }
            .append(Timer.publish(every: 120, tolerance: 5, on: .main, in: .common).autoconnect())
            .flatMap { [weak self] _ -> AnyPublisher<Void, Never> in
                guard let self = self else {
                    return Empty().eraseToAnyPublisher()
                }
                return self.refreshMap(appState: appState)
            }
            .sink {}
    }
    
    func presentPreselectedPlace(place: Place, appState: AppState, globalViewState: GlobalViewState) {
        if self.displayedInitialBottomSheetForPresentedPost {
            // Already presented
            return
        }
        loadPreselectedPlace = appState.loadPlaceIcon(for: place)
            .sink { completion in
                if case let .failure(error) = completion {
                    print("Error loading place", error)
                    globalViewState.setError("Failed to load place details")
                }
            } receiveValue: { [weak self] icon in
                guard let self = self else {
                    return
                }
                let pin = PlaceAnnotation(pin: MapPlace(place: place, icon: icon), zIndex: 0)
                self.presentedPin = pin
                if !self.mapAnnotations.contains(where: { $0.place.placeId == pin.place.placeId }) {
                    self.mapAnnotations.append(pin)
                }
                self.modalState = .tiny
                self.displayedInitialBottomSheetForPresentedPost = true
            }
    }
    
    func refreshMap(appState: AppState) -> AnyPublisher<Void, Never> {
        appState.refreshMap()
            .catch { error -> AnyPublisher<[MapPlace], Never> in
                print("Error when getting map", error)
                return Just([]).eraseToAnyPublisher()
            }
            .map { [weak self] places in
                self?.updateAnnotations(pins: places)
            }
            .eraseToAnyPublisher()
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
            PlaceAnnotation(pin: pin, zIndex: i)
        })
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
