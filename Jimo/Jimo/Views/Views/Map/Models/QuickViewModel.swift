//
//  QuickViewModel.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/22/22.
//

import Combine
import Foundation
import MapKit
import SwiftUI

struct PlaceCache {
    var place: Place?
    var posts: [PostId] = []
    var loading: Bool
}

struct PlaceCacheKey: Hashable {
    var placeId: PlaceId
    var loadStrategy: MapLoadStrategy
    var userFilter: Set<UserId>
    var categoryFilter: Set<String>
}

class QuickViewModel: ObservableObject {
    let nc = NotificationCenter.default

    @Published var allPosts: [PostId: Post] = [:]
    @Published var placePostsCache: [PlaceCacheKey: PlaceCache] = [:]

    var mapItemCache: [PlaceId: MKMapItem] = [:]

    private var cancelBag: Set<AnyCancellable> = .init()

    init() {
        nc.addObserver(self, selector: #selector(postLiked), name: PostPublisher.postLiked, object: nil)
        nc.addObserver(self, selector: #selector(postUpdated), name: PostPublisher.postUpdated, object: nil)
    }

    @objc private func postLiked(notification: Notification) {
        let like = notification.object as! PostLikePayload
        allPosts[like.postId]?.likeCount = like.likeCount
        allPosts[like.postId]?.liked = like.liked
    }

    @objc private func postUpdated(notification: Notification) {
        let post = notification.object as! Post
        allPosts[post.postId] = post
    }

    private func cacheKey(for placeId: PlaceId, mapViewModel: MapViewModelV2) -> PlaceCacheKey {
        PlaceCacheKey(
            placeId: placeId,
            loadStrategy: mapViewModel.mapLoadStrategy,
            userFilter: mapViewModel.selectedUsers,
            categoryFilter: mapViewModel.selectedCategories
        )
    }

    func getPosts(for placeId: PlaceId, mapViewModel: MapViewModelV2) -> [Post] {
        let postIds = placePostsCache[cacheKey(for: placeId, mapViewModel: mapViewModel)]?.posts ?? []
        return postIds.compactMap { allPosts[$0] }
    }

    func getPlace(for placeId: PlaceId, mapViewModel: MapViewModelV2) -> Place? {
        placePostsCache[cacheKey(for: placeId, mapViewModel: mapViewModel)]?.place
    }

    func isLoading(placeId: PlaceId, mapViewModel: MapViewModelV2) -> Bool {
        placePostsCache[cacheKey(for: placeId, mapViewModel: mapViewModel)]?.loading ?? true
    }

    func loadPosts(appState: AppState, mapViewModel: MapViewModelV2, placeId: PlaceId) {
        let cacheKey = cacheKey(for: placeId, mapViewModel: mapViewModel)
        if let cachedPlace = placePostsCache[cacheKey], cachedPlace.place != nil || cachedPlace.loading {
            print("Already cached or loading posts")
            return
        }
        placePostsCache[cacheKey] = PlaceCache(loading: true)
        let categories = Array(mapViewModel.selectedCategories)
        var request: AnyPublisher<[Post], APIError>
        switch mapViewModel.mapLoadStrategy {
        case .everyone:
            request = appState.getGlobalMutualPostsV3(for: placeId, categories: categories)
        case .following:
            request = appState.getFollowingMutualPostsV3(for: placeId, categories: categories)
        case .custom:
            request = appState.getCustomMutualPostsV3(
                for: placeId, categories: categories, users: Array(mapViewModel.selectedUsers))
        case .none:
            return
        }
        print("Loading \(mapViewModel.mapLoadStrategy) posts")
        request.sink { [weak self] completion in
            guard let self = self else {
                return
            }
            if case let .failure(error) = completion {
                print("Could not load posts", error)
                withAnimation {
                    self.placePostsCache[cacheKey]?.loading = false
                }
            }
        } receiveValue: { [weak self] posts in
            guard let self = self else {
                return
            }
            withAnimation {
                for post in posts {
                    self.allPosts[post.id] = post
                }
                self.placePostsCache[cacheKey]?.posts = posts.map { $0.id }
                self.placePostsCache[cacheKey]?.place = posts.first?.place
                self.placePostsCache[cacheKey]?.loading = false
            }
        }
        .store(in: &cancelBag)
    }

    func getMapItem(place: Place, handle: @escaping (MKMapItem?) -> Void) {
        if let mapItem = mapItemCache[place.id] {
            handle(mapItem)
        }
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: place.location.latitude, longitude: place.location.longitude)
        geocoder.reverseGeocodeLocation(location) { response, error in
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
                                self.mapItemCache[place.id] = mapItem
                                return handle(mapItem)
                            }
                        }
                    }
                    let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                    self.mapItemCache[place.id] = mapItem
                    handle(mapItem)
                }
            } else {
                handle(nil)
            }
        }
    }
}
