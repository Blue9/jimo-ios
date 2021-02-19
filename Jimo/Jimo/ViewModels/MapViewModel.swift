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
    let preselectedPost: Post? // If we are navigating to the map from a post
    
    /// When first launching the map, if preselectedPost != nil we want to open the bottom sheet for it.
    /// This lets us know whether we have done that or not so we don't repeatedly open the bottom sheet.
    var displayedInitialBottomSheetForPresentedPost: Bool = false

    var regionCancellable: Cancellable? = nil
    var annotationsCancellable: Cancellable? = nil
    var cancellable: Cancellable? = nil
    
    @Published var region = defaultRegion
    @Published var presentedPin: PlaceAnnotation?
    @Published var results: [MKMapItem]?
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
    
    init(appState: AppState, preselectedPost: Post? = nil) {
        self.appState = appState
        self.preselectedPost = preselectedPost
        if let post = preselectedPost {
            region.center = post.location
            region.span = MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        }
    }
    
    func listenToChanges() {
        print("Listening to map changes")
        regionCancellable = $region
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .sink { [weak self] region in
                self?.refreshMap()
            }
        annotationsCancellable = appState.mapModel.$posts
            .sink { [weak self] posts in self?.updateAnnotations(posts: posts) }
    }
    
    func refreshMap() {
        let regionToLoad = MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(
                latitudeDelta: region.span.latitudeDelta,
                longitudeDelta: region.span.longitudeDelta))
        cancellable = appState.refreshMap(region: regionToLoad)
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    print(error)
                }
            }, receiveValue: {})
    }
    
    func updateAnnotations(posts: [PostId]) {
        var places: [Location: [Post]] = [:]
        posts.map({ appState.allPosts.posts[$0]! })
            .forEach({ post in
                if let location = post.customLocation {
                    places[location] = (places[location] ?? []) + [post]
                } else {
                    places[post.place.location] = (places[post.place.location] ?? []) + [post]
                }
            })
        mapAnnotations = places.enumerated().map({ (i, e) in
            let (location, posts) = e
            return PlaceAnnotation(posts: posts, coordinate: location.coordinate(), zIndex: i)
        })
        if let post = preselectedPost, !displayedInitialBottomSheetForPresentedPost {
            self.mapAnnotations.forEach({ placeAnnotation in
                if placeAnnotation.posts.map({ $0.postId }).contains(post.postId) {
                    presentedPin = placeAnnotation
                    modalState = .tiny
                    displayedInitialBottomSheetForPresentedPost = true
                }
            })
        }
    }
}


class PlaceAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let posts: [Post]
    let zIndex: Int
    
    init(posts: [Post], coordinate: CLLocationCoordinate2D, zIndex: Int) {
        self.posts = posts
        self.coordinate = coordinate
        self.zIndex = zIndex
    }
    
    func place() -> Place {
        return self.posts.first!.place
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let placeAnnotation = object as? PlaceAnnotation {
            return coordinate == placeAnnotation.coordinate && posts.elementsEqual(placeAnnotation.posts)
        }
        return false
    }
}
