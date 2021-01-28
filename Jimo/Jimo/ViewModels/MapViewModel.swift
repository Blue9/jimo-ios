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
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    
    var appState: AppState
    var regionCancellable: Cancellable? = nil
    var cancellable: Cancellable? = nil
    
    @Environment(\.presentationMode) var presentation
    
    @Published var annotations: [PostAnnotation] = []
    @Published var region = defaultRegion
    
    @Published var presentBottomSheet = false
    @Published var presentedPost: PostId? = nil
    
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
            }, receiveValue: {
                self.updateAnnotations()
            })
    }
    
    func updateAnnotations() {
        annotations = appState.mapModel.posts
            .map({ appState.allPosts.posts[$0]! })
            .map({ PostAnnotation(post: $0) })
    }
}
