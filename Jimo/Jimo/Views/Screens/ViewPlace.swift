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
    let address: String
    let phoneNumber: String
    let website: String
}

struct ViewPlace: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    @Environment(\.backgroundColor) var backgroundColor
    
    let place: Place?
    let mapItem: MKMapItem?
    
    @State private var placeParams = PlaceParams(
        address: "Loading address...",
        phoneNumber: "Loading phone number...",
        website: "Loading website...")
    @State private var setParams = false
    
    @State private var loadingMutualPosts = false
    @State private var mutualPosts: [Post]?
    @State private var mutualPostsCancellable: AnyCancellable?
    
    init(place: Place, mutualPosts: [Post]? = nil) {
        self.place = place
        self.mapItem = nil
    }
    
    init(mapItem: MKMapItem) {
        self.mapItem = mapItem
        self.place = nil
    }
    
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
        return components
            .compactMap({ $0 })
            .joined(separator: ", ")
    }
    
    private func getAddress(place: Place, completionHandler: @escaping MKLocalSearch.CompletionHandler) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = place.name
        request.region = MKCoordinateRegion(
            center: place.location.coordinate(),
            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        let localSearch = MKLocalSearch(request: request)
        localSearch.start(completionHandler: completionHandler)
    }
    
    private func getParams(mapItem: MKMapItem) -> PlaceParams{
        return PlaceParams(
            address: ViewPlace.getAddress(placemark: mapItem.placemark),
            phoneNumber: mapItem.phoneNumber ?? "Unknown",
            website: mapItem.url?.absoluteString ?? "Unknown")
    }
    
    private func loadMutualPosts() {
        guard let place = place else {
            return
        }
        loadingMutualPosts = true
        mutualPostsCancellable = appState.getMutualPosts(for: place.placeId)
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
    
    var name: String {
        if let place = place {
            return place.name
        } else if let mapItem = mapItem {
            return mapItem.name ?? ""
        }
        return ""
    }
    
    var location: CLLocationCoordinate2D? {
        if let place = place {
            return place.location.coordinate()
        } else if let mapItem = mapItem {
            return mapItem.placemark.coordinate
        }
        return nil
    }
    
    var viewPlaceBody: some View {
        ScrollView {
            HStack {
                VStack(alignment: .leading) {
                    Text(name)
                        .font(Font.custom(Poppins.semiBold, size: 20))
                        .bold()
                    Text(placeParams.address)
                }
                Spacer()
                
                Button(action: {
                    let q = name.split(separator: " ").joined(separator: "+")
                    var url: String
                    if let location = location {
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
                    
                    if setParams, let url = URL(string: "tel://\(placeParams.phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            Text(placeParams.phoneNumber)
                        }
                    } else {
                        Text(placeParams.phoneNumber)
                    }
                }
                Spacer()
            }
            Divider()
            HStack(alignment: .bottom) {
                VStack(alignment: .leading) {
                    Text("Website")
                        .foregroundColor(.gray)
                    if setParams, let url = URL(string: placeParams.website) {
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            Text(placeParams.website)
                        }
                    } else {
                        Text(placeParams.website)
                    }
                }
                Spacer()
            }
            Divider()
            if loadingMutualPosts {
                ProgressView()
            } else if let mutualPosts = mutualPosts, mutualPosts.count > 0 {
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
        .onAppear {
            if let place = place {
                getAddress(place: place) { response, error in
                    guard let response = response,
                          let firstResult = response.mapItems.first else {
                        setParams = true
                        return
                    }
                    placeParams = getParams(mapItem: firstResult)
                    setParams = true
                }
            } else if let mapItem = mapItem {
                self.placeParams = getParams(mapItem: mapItem)
                self.setParams = true
            }
        }
    }
    
    var body: some View {
        viewPlaceBody
            .background(backgroundColor)
            .onAppear {
                if mutualPosts == nil {
                    self.loadMutualPosts()
                }
            }
    }
}

struct ViewPlace_Previews: PreviewProvider {
    static var previews: some View {
        ViewPlace(place: Place(placeId: "placeId", name: "Covent Garden", location: Location(coord: .init(latitude: 51.5117, longitude: -0.1240))))
    }
}
