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
    
    var displayName: String { get }
    
    var location: CLLocationCoordinate2D? { get }
    
    var loadingMutualPosts: Bool { get }
    var mutualPosts: [Post]? { get }
    
    func loadMutualPosts(appState: AppState, globalViewState: GlobalViewState)
    
    func getMapItem(handle: @escaping (MKMapItem?) -> Void)
}

class ViewPinVM: ViewPlaceVM {
    static let categoryEmojis = [
        "food": "🍹",
        "activity": "🥾",
        "attraction": "🏛️",
        "lodging": "🛌",
        "shopping": "🛍️",
    ]
    let pin: MapPlace
    
    @Published var loadingMutualPosts = false
    @Published var mutualPosts: [Post]?
    @Published var mutualPostsCancellable: AnyCancellable?
    
    var name: String {
        pin.place.name
    }
    
    var displayName: String {
        name + emojiSuffix
    }
    
    var emojiSuffix: String {
        if let category = pin.icon.category,
           let emoji = ViewPinVM.categoryEmojis[category]{
            return " " + emoji
        } else {
            return ""
        }
    }
    
    var location: CLLocationCoordinate2D? {
        pin.place.location.coordinate()
    }
    
    init(pin: MapPlace) {
        self.pin = pin
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
                self.mutualPosts = posts.compactMap { appState.allPosts.posts[$0] }
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
    
    var displayName: String {
        name
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
            placemark.administrativeArea,
            placemark.country];
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
        ScrollView {
            HStack {
                VStack(alignment: .leading) {
                    Text(viewPlaceVM.displayName)
                        .font(Font.custom(Poppins.semiBold, size: 20))
                        .bold()
                    Text(placeParams.address ?? "Loading address...")
                }
                Spacer()
                
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
                        .font(Font.custom(Poppins.regular, size: 14))
                        .frame(maxHeight: 20)
                        .foregroundColor(.black)
                        .padding(10)
                        .background(Color.init(red: 0.6,
                                               green: 0.6,
                                               blue: 0.6,
                                               opacity: 0.3))
                        .cornerRadius(10)
                }
            }
            Divider()
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("Phone")
                        .foregroundColor(.gray)
                    
                    if loadedParams {
                        if let number = placeParams.phoneNumber {
                            Button(action: {
                                if let url = URL(string: "tel://\(number.replacingOccurrences(of: " ", with: ""))") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(number)
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
                        .foregroundColor(.gray)
                    if loadedParams {
                        if let website = placeParams.website {
                            Button(action: {
                                if let url = URL(string: website) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(website)
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
            Divider()
            if viewPlaceVM.loadingMutualPosts {
                ProgressView()
            } else if let mutualPosts = viewPlaceVM.mutualPosts, mutualPosts.count > 0 {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Friends who have been here")
                            .foregroundColor(.gray)
                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(mutualPosts, id: \.postId) { post in
                                    NavigationLink(destination: ViewPost(postId: post.postId)) {
                                        URLImage(url: post.user.profilePictureUrl, failure: Image(systemName: "person.crop.circle"))
                                            .aspectRatio(contentMode: .fill)
                                            .background(Color.white)
                                            .foregroundColor(.gray)
                                            .frame(width: 40, height: 40, alignment: .center)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                }
                Divider()
            }
            Spacer()
        }
        .font(Font.custom(Poppins.regular, size: 16))
        .padding()
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
            .background(backgroundColor)
            .appear {
                if viewPlaceVM.mutualPosts == nil {
                    viewPlaceVM.loadMutualPosts(appState: appState, globalViewState: globalViewState)
                }
            }
    }
}

//struct ViewPlace_Previews: PreviewProvider {
//    static var previews: some View {
//        ViewPlace(pin: MapPlace(
//            place: Place(placeId: "placeId", name: "Covent Garden", location: Location(coord: .init(latitude: 51.5117, longitude: -0.1240))),
//            icon: .init(category: "food", iconUrl: nil, numMutualPosts: 10)
//        ))
//    }
//}
