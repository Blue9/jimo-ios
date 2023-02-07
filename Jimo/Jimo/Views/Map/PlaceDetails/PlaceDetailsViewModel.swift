//
//  PlaceDetailsViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/7/23.
//

import SwiftUI
import Combine
import MapKit

enum PlaceDetailsLoadStatus: Equatable {
    case loading, loaded, cached
}

class PlaceDetailsViewModel: ObservableObject {
    private var cancelBag: Set<AnyCancellable> = .init()

    struct MuxedPlaceDetails: Equatable {
        fileprivate var mkMapItem: MKMapItem?

        /// Jimo place details
        fileprivate var details: GetPlaceDetailsResponse?

        init(mkMapItem: MKMapItem? = nil, details: GetPlaceDetailsResponse? = nil) {
            self.mkMapItem = mkMapItem
            self.details = details
        }
    }

    var cancellable: AnyCancellable?
    var createPostVM = CreatePostVM()

    @Published var showCreatePost = false

    @Published var loadStatus: PlaceDetailsLoadStatus = .loading

    @Published var muxedPlaceDetails: MuxedPlaceDetails? {
        didSet {
            DispatchQueue.main.async {
                self.loadStatus = .loaded
            }
        }
    }

    var mkMapItem: MKMapItem? { muxedPlaceDetails?.mkMapItem }
    var details: GetPlaceDetailsResponse? { muxedPlaceDetails?.details }

    // MARK: - Initialization
    private var mapListener = PostPlaceListener()

    func initialize(appState: AppState, viewState: GlobalViewState) {
        mapListener.onPostDeleted = { [weak self] postId in
            DispatchQueue.main.async {
                if self?.muxedPlaceDetails?.details?.myPost?.postId == postId {
                    self?.muxedPlaceDetails?.details?.myPost = nil
                }
            }
        }
        mapListener.onPlaceSave = { [weak self] payload in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async {
                /// Either we have a place ID or a MKMapItem to compare
                if let place = self.details?.place, place.id == payload.placeId {
                    /// Place was saved, details is non-nil
                    if let save = payload.save {
                        // Saved
                        self.muxedPlaceDetails?.details?.mySave = save
                    } else {
                        // Unsaved
                        self.muxedPlaceDetails?.details?.mySave = nil
                    }
                } else if self.details == nil,
                          let mapItem = self.mkMapItem, mapItem.maybeCreatePlaceRequest == payload.createPlaceRequest {
                    /// Place was saved, details is nil
                    if let save = payload.save {
                        // Saved
                        self.muxedPlaceDetails?.details = .init(place: save.place, mySave: save)
                    }
                }
            }
        }
    }

    // MARK: - Map view model integration

    func selectPlace(_ placeId: PlaceId?, appState: AppState, viewState: GlobalViewState) {
        if self.place?.placeId == placeId {
            // Just use the last-loaded place details
            self.loadStatus = .cached
            return
        }
        self.loadStatus = .loading
        guard let placeId = placeId else {
            // User tapped on a "fake" pin
            viewState.setError("Cannot load place details")
            return
        }
        appState.getPlaceDetails(placeId: placeId)
            .sink { completion in
                if case let .failure(error) = completion {
                    print("Error when getting place details", error)
                    viewState.setError("Could not load place details")
                }
            } receiveValue: { [weak self] placeDetails in
                self?.muxedPlaceDetails = .init(mkMapItem: nil, details: placeDetails)
                self?.loadMapItemForPlaceDetails()
            }
            .store(in: &cancelBag)
    }

    func selectMapItem(
        _ mapItem: MKMapItem,
        appState: AppState,
        viewState: GlobalViewState,
        onPlaceFound: @escaping (PlaceId?, CLLocationCoordinate2D) -> Void
    ) {
        self.loadStatus = .loading
        let placeName = mapItem.placemark.name ?? ""
        self.muxedPlaceDetails = .init(mkMapItem: mapItem, details: nil)
        appState.findPlace(
            name: placeName,
            latitude: mapItem.placemark.coordinate.latitude,
            longitude: mapItem.placemark.coordinate.longitude
        ).flatMap { response in
            guard let place = response.place else {
                onPlaceFound(nil, mapItem.placemark.coordinate)
                return Just<GetPlaceDetailsResponse?>(nil)
                    .setFailureType(to: APIError.self)
                    .eraseToAnyPublisher()
            }
            onPlaceFound(place.placeId, place.location.coordinate())
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
            self?.muxedPlaceDetails = .init(
                mkMapItem: mapItem,
                details: placeDetails
            )
        }
        .store(in: &cancelBag)
    }

    private func loadMapItemForPlaceDetails() {
        guard let place = place else {
            return
        }
        let location = CLLocation(latitude: place.location.latitude, longitude: place.location.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { response, _ in
            if let response = response, let placemark = response.first {
                // Got the CLPlacemark, now try to get the MKMapItem to get the business details
                let searchRequest = MKLocalSearch.Request()
                searchRequest.region = .init(center: place.location.coordinate(), span: .init(latitudeDelta: 0, longitudeDelta: 0))
                searchRequest.naturalLanguageQuery = place.name
                MKLocalSearch(request: searchRequest).start { (response, _) in
                    if let response = response {
                        for mapItem in response.mapItems {
                            if let placemarkLocation = placemark.location,
                               let mapItemLocation = mapItem.placemark.location,
                               mapItemLocation.distance(from: placemarkLocation) < 10 {
                                self.muxedPlaceDetails?.mkMapItem = mapItem
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - API functions

    func savePlace(note: String, appState: AppState, viewState: GlobalViewState) {
        print("Saving place")
        cancellable = appState.savePlace(
            placeId: place?.placeId,
            maybeCreatePlaceRequest: mkMapItem?.maybeCreatePlaceRequest,
            note: note
        ).sink { completion in
            if case .failure = completion {
                viewState.setError("Could not save place.")
            }
        } receiveValue: { _ in
            // maplistener.onPlaceSaved will handle this
        }
    }

    func unsavePlace(appState: AppState, viewState: GlobalViewState) {
        guard let place = details?.place else {
            return
        }
        cancellable = appState.unsavePlace(place.placeId).sink { completion in
            if case .failure = completion {
                viewState.setError("Could not unsave place.")
            }
        } receiveValue: { _ in
            // maplistener.onPlaceSaved will handle this
        }
    }

    // MARK: - View only functions

    func showCreateOrEditPostSheet() {
        self.resetCreatePostVM()
        if let post = details?.myPost {
            createPostVM.initAsEditor(post)
        } else if let place = place {
            createPostVM.selectPlace(place: place)
        } else if let mapItem = mkMapItem {
            createPostVM.selectPlace(place: mapItem)
        }
        showCreatePost = true
    }

    private func resetCreatePostVM() {
        self.createPostVM.resetAll()
        createPostVM.onCreate = { [weak self] post in
            if self?.muxedPlaceDetails?.details != nil {
                self?.muxedPlaceDetails?.details?.myPost = post
            } else {
                self?.muxedPlaceDetails?.details = .init(place: post.place, myPost: post)
            }
        }
    }

    func openInMaps() {
        if UIApplication.shared.canOpenURL(URL(string: "comgooglemaps://")!) {
            openInGoogleMaps()
        } else {
            openInAppleMaps()
        }
    }

    private func openInGoogleMaps() {
        let scheme = "comgooglemaps://"
        let query = self.name.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? self.name
        let url = "\(scheme)?q=\(query)&center=\(self.latitude),\(self.longitude)"
        UIApplication.shared.open(URL(string: url)!)
    }

    private func openInAppleMaps() {
        if let mapItem = mkMapItem {
            mapItem.openInMaps()
        } else {
            let q = self.name.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? self.name
            let sll = "\(self.latitude),\(self.longitude)"
            let url = "http://maps.apple.com/?q=\(q)&sll=\(sll)&z=10"
            if let encoded = url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
               let url = URL(string: encoded) {
                UIApplication.shared.open(url)
            } else {
                print("URL not valid", url)
            }
        }
    }
}

extension PlaceDetailsViewModel {
    var place: Place? { details?.place }

    var name: String { place?.name ?? mkMapItem?.name ?? "" }

    var category: String? { place?.category ?? mkMapItem?.pointOfInterestCategory?.toString() }

    var latitude: Double { place?.location.latitude ?? mkMapItem?.placemark.coordinate.latitude ?? 0 }

    var longitude: Double { place?.location.longitude ?? mkMapItem?.placemark.coordinate.longitude ?? 0 }

    var communityPosts: [Post] { details?.communityPosts ?? [] }

    var featuredPosts: [Post] { details?.featuredPosts ?? [] }

    var followingPosts: [Post] { details?.followingPosts ?? [] }

    var isSaved: Bool { details?.mySave != nil }

    var isPosted: Bool { details?.myPost != nil }

    var phoneNumber: String? { mkMapItem?.phoneNumber }

    var website: URL? { mkMapItem?.url }

    func address() -> String {
        guard let mkMapItem = mkMapItem else {
            return ""
        }
        let placemark = mkMapItem.placemark
        var streetAddress: String?
        if let subThoroughfare = placemark.subThoroughfare,
           let thoroughfare = placemark.thoroughfare {
            streetAddress = subThoroughfare + " " + thoroughfare
        }
        let components = [
            streetAddress,
            placemark.locality,
            placemark.administrativeArea
        ]
        return components.compactMap({ $0 }).joined(separator: ", ")
    }
}
