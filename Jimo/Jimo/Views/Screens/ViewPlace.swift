//
//  ViewPlace.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/28/21.
//

import SwiftUI
import MapKit
import Combine

struct PlaceParams {
    var address: String?
    var phoneNumber: String?
    var website: String?
}

protocol ViewPlaceVM: ObservableObject {
    var name: String { get }
    
    var location: CLLocationCoordinate2D? { get }
    
    var loadingMutualPosts: Bool { get }
    var mutualPosts: [Post]? { get }
    
    func loadMutualPosts(appState: AppState, globalViewState: GlobalViewState)
    
    func getMapItem(handle: @escaping (MKMapItem?) -> Void)
}

class ViewPinVM: ViewPlaceVM {
    let nc = NotificationCenter.default
    let pin: MapPlace
    
    @Published var loadingMutualPosts = false
    @Published var mutualPosts: [Post]?
    @Published var mutualPostsCancellable: AnyCancellable?
    
    var name: String {
        pin.place.name
    }
    
    var location: CLLocationCoordinate2D? {
        pin.place.location.coordinate()
    }
    
    init(pin: MapPlace) {
        self.pin = pin
        nc.addObserver(self, selector: #selector(postLiked), name: PostPublisher.postLiked, object: nil)
    }
    
    @objc private func postLiked(notification: Notification) {
        let like = notification.object as! PostLikePayload
        let postIndex = mutualPosts?.indices.first(where: { mutualPosts?[$0].postId == like.postId })
        if let i = postIndex {
            mutualPosts?[i].likeCount = like.likeCount
            mutualPosts?[i].liked = like.liked
        }
    }
    
    func loadMutualPosts(appState: AppState, globalViewState: GlobalViewState) {
        loadingMutualPosts = true
        mutualPostsCancellable = appState.getMutualPosts(for: pin.place.placeId)
            .sink { completion in
                if case let .failure(error) = completion {
                    print("Error when loading mutual posts", error)
                    globalViewState.setError("Failed to load mutual posts")
                }
                self.loadingMutualPosts = false
            } receiveValue: { posts in
                self.mutualPosts = posts
            }
    }
    
    func getMapItem(handle: @escaping (MKMapItem?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: pin.place.location.latitude, longitude: pin.place.location.longitude)
        let place = pin.place
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
                                return handle(mapItem)
                            }
                        }
                    }
                    handle(.init(placemark: .init(placemark: placemark)))
                }
            } else {
                handle(nil)
            }
        }
    }
}

class ViewMKMapItemVM: ViewPlaceVM {
    let mapItem: MKMapItem
    
    var loadingMutualPosts = false
    var mutualPosts: [Post]?
    
    var name: String {
        mapItem.name ?? "Unknown"
    }
    
    var location: CLLocationCoordinate2D? {
        mapItem.placemark.coordinate
    }
    
    init(mapItem: MKMapItem) {
        self.mapItem = mapItem
    }
    
    func loadMutualPosts(appState: AppState, globalViewState: GlobalViewState) {
    }
    
    func getMapItem(handle: (MKMapItem?) -> Void) {
        handle(mapItem)
    }
}

struct ViewPlace<T>: View where T: ViewPlaceVM {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    
    @StateObject var viewPlaceVM: T
    
    @State private var placeParams = PlaceParams()
    @State private var loadedParams = false
    
    @State private var mapItem: MKMapItem?
    
    static func getAddress(placemark: CLPlacemark) -> String {
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
        let address = components.compactMap({ $0 }).joined(separator: ", ")
        if let countryCode = placemark.isoCountryCode {
            return getEmojiFromCountryCode(countryCode: countryCode) + " " + address
        } else {
            return address
        }
    }
    
    static func getEmojiFromCountryCode(countryCode: String) -> String {
        let base = 127397
        var emoji = String.UnicodeScalarView()
        for i in countryCode.utf16 {
            if let c = UnicodeScalar(base + Int(i)) {
                emoji.append(c)
            }
        }
        return String(emoji)
    }
    
    private func getParams(mapItem: MKMapItem) -> PlaceParams{
        return PlaceParams(
            address: ViewPlace.getAddress(placemark: mapItem.placemark),
            phoneNumber: mapItem.phoneNumber,
            website: mapItem.url?.absoluteString)
    }
    
    var viewPlaceBody: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(viewPlaceVM.name)
                        .font(.system(size: 18))
                        .bold()
                    Text(placeParams.address ?? "Loading address...")
                }
                Spacer()
            }
            Divider()
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("See friends' posts")
                        .foregroundColor(.black)
                    ScrollView(.horizontal) {
                        HStack {
                            if viewPlaceVM.loadingMutualPosts {
                                ProgressView()
                            } else if let mutualPosts = viewPlaceVM.mutualPosts, mutualPosts.count > 0 {
                                ForEach(mutualPosts, id: \.postId) { post in
                                    NavigationLink(destination: ViewPost(post: post)) {
                                        URLImage(
                                            url: post.user.profilePictureUrl,
                                            loading: Image(systemName: "person.crop.circle"),
                                            failure: Image(systemName: "person.crop.circle")
                                        )
                                            .aspectRatio(contentMode: .fill)
                                            .background(Color.white)
                                            .foregroundColor(.gray)
                                            .frame(width: 60, height: 60, alignment: .center)
                                            .cornerRadius(30)
                                            .shadow(radius: 4, x: 1, y: -1)
                                            .contentShape(Rectangle())
                                    }
                                }
                            } else {
                                Text("-")
                            }
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 10)
                    }
                }
                Spacer()
            }
            Divider()
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("Phone")
                        .foregroundColor(.black)
                    
                    if loadedParams {
                        if let number = placeParams.phoneNumber {
                            Button(action: {
                                if let url = URL(string: "tel://\(number.replacingOccurrences(of: " ", with: ""))") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(number).lineLimit(1)
                            }
                        } else {
                            Text("-")
                        }
                    } else {
                        Text("Loading phone number...")
                    }
                }
                Spacer()
            }
            Divider()
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("Website")
                        .foregroundColor(.black)
                    if loadedParams {
                        if let website = placeParams.website {
                            Button(action: {
                                if let url = URL(string: website) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(website).lineLimit(1)
                            }
                        } else {
                            Text("-")
                        }
                    } else {
                        Text("Loading website...")
                    }
                }
                Spacer()
            }
            
            Button(action: {
                if let mapItem = mapItem {
                    mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
                } else {
                    let q = viewPlaceVM.name.split(separator: " ").joined(separator: "+")
                    var url: String
                    if let location = viewPlaceVM.location {
                        let sll = "\(location.latitude),\(location.longitude)"
                        url = "http://maps.apple.com/?q=\(q)&sll=\(sll)&z=10"
                    } else {
                        url = "http://maps.apple.com/?q=\(q)&z=10"
                    }
                    if let encoded = url.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed),
                       let url = URL(string: encoded) {
                        UIApplication.shared.open(url)
                    } else {
                        print("URL not valid", url)
                    }
                }
            }) {
                Text("Directions")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: 10)
                    .padding(.vertical, 15)
                    .background(Color.blue)
                    .cornerRadius(2)
            }
            
            Spacer()
        }
        .font(.system(size: 16))
        .padding(.horizontal)
        .appear {
            viewPlaceVM.getMapItem(handle: { mapItem in
                if let mapItem = mapItem {
                    self.mapItem = mapItem
                    placeParams = getParams(mapItem: mapItem)
                }
                loadedParams = true
            })
        }
    }
    
    var body: some View {
        viewPlaceBody
            .appear {
                if viewPlaceVM.mutualPosts == nil {
                    viewPlaceVM.loadMutualPosts(appState: appState, globalViewState: globalViewState)
                }
            }
    }
}
