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
    
    var appState: AppState
    var regionCancellable: Cancellable? = nil
    var cancellable: Cancellable? = nil
    
    @Published var region = defaultRegion
    @Published var presentedPost: Post?
    @Published var results: [MKMapItem]?
    @Published var modalState: ModalSnapState = .invisible {
        didSet {
            if modalState == .invisible {
                presentedPost = nil
                results = nil
            }
        }
    }
    
    init(appState: AppState) {
        self.appState = appState
        regionCancellable = $region
            .debounce(for: 0.1, scheduler: DispatchQueue.main)
            .sink { region in self.refreshMap() }
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
}

class PostAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let post: Post
    let zIndex: Int
    
    init(post: Post, zIndex: Int) {
        self.zIndex = zIndex
        self.post = post
        if let location = post.customLocation {
            self.coordinate = location.coordinate()
        } else {
            self.coordinate = post.place.location.coordinate()
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let postAnnotation = object as? PostAnnotation {
            return post.postId == postAnnotation.post.postId
        }
        return false
    }
}
