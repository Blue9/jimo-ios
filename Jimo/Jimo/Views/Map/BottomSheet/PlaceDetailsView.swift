//
//  PlaceDetailsView.swift
//  Jimo
//
//  Created by admin on 12/23/22.
//

import Combine
import MapKit
import SwiftUI
import SwiftUIPager

struct PlaceDetailsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState

    @ObservedObject var viewModel: PlaceDetailsViewModel

    @State private var initialized = false

    var body: some View {
        BasePlaceDetailsView(viewModel: viewModel)
            .onAppear {
                DispatchQueue.main.async {
                    if !initialized {
                        initialized = true
                        viewModel.initialize(appState: appState, viewState: viewState)
                    }
                }
            }
    }
}

private struct BasePlaceDetailsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: PlaceDetailsViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            HStack(spacing: 10) {
                CreatePostButton(viewModel: viewModel)
                SavePlaceButton(viewModel: viewModel)
            }.padding(.horizontal, 10)

            HStack {
                if let phoneNumber = viewModel.phoneNumber {
                    PhoneNumberButton(phoneNumber: phoneNumber)
                }
                if let url = viewModel.website {
                    WebsiteButton(url: url)
                }
                OpenInMapsButton(viewModel: viewModel)

                Spacer()
            }
            .padding(.horizontal, 10)
            .foregroundColor(.white)
            .padding(.bottom, 10)

            VStack(alignment: .leading) {
                if let save = viewModel.details?.mySave {
                    VStack(alignment: .leading, spacing: 10) {
                        Divider()
                        HStack {
                            Text("Saved \(appState.relativeTime(for: save.createdAt)) - ")
                                .italic()
                            +
                            Text(save.note.isEmpty ? "No note" : save.note)
                        }.font(.caption)
                        Divider()
                    }
                }

                if let post = viewModel.details?.myPost {
                    HStack {
                        Text("Me")
                            .font(.system(size: 15))
                            .bold()
                        Spacer()
                    }
                    PostPage(post: post).contentShape(Rectangle())
                }

                if viewModel.followingPosts.count > 0 {
                    PostCarousel(
                        text: "Friends' Posts (\(viewModel.followingPosts.count))",
                        posts: viewModel.followingPosts
                    )
                }

                if viewModel.featuredPosts.count > 0 {
                    PostCarousel(
                        text: "Featured (\(viewModel.featuredPosts.count))",
                        posts: viewModel.featuredPosts
                    )
                }

                if viewModel.communityPosts.count > 0 {
                    PostCarousel(
                        text: "Community (\(viewModel.communityPosts.count))",
                        posts: viewModel.communityPosts
                    )
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 20)

            Spacer()
        }
        .padding(.bottom, 49)
    }
}

private struct CreatePostButton: View {
    @ObservedObject var viewModel: PlaceDetailsViewModel

    var body: some View {
        Button {
            DispatchQueue.main.async {
                Analytics.track(.mapCreatePostTapped)
                viewModel.showCreateOrEditPostSheet()
            }
        } label: {
            HStack {
                Spacer()
                Text(viewModel.isPosted ? "Update" : "Rate")
                    .font(.system(size: 15))
                    .fontWeight(.medium)
                Image(systemName: "plus.app")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                Spacer()
            }
            .padding(.vertical, 10)
            .foregroundColor(.white)
            .background(.blue)
            .cornerRadius(5)
        }

        .sheet(isPresented: $viewModel.showCreatePost) {
            CreatePostWithModel(
                createPostVM: viewModel.createPostVM,
                presented: $viewModel.showCreatePost
            )
        }
    }
}

private struct SavePlaceButton: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    @ObservedObject var viewModel: PlaceDetailsViewModel

    @State private var showSaveNoteAlert = false

    var body: some View {
        Button {
            DispatchQueue.main.async {
                if viewModel.isSaved {
                    viewModel.unsavePlace(appState: appState, viewState: viewState)
                } else {
                    showSaveNoteAlert = true
                }
            }
        } label: {
            HStack {
                Spacer()
                Text(viewModel.isSaved ? "Saved" : "Save")
                    .font(.system(size: 15))
                    .fontWeight(.medium)
                Image(systemName: viewModel.isSaved ? "bookmark.fill" : "bookmark")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)
                Spacer()
            }
            .padding(.vertical, 10)
            .foregroundColor(.white)
            .background(.orange)
            .cornerRadius(5)
        }
        .textAlert(
            isPresented: $showSaveNoteAlert,
            title: "Save \(viewModel.name)",
            message: "Add a note (Optional)",
            submitText: "Save",
            action: { note in
                Analytics.track(.mapSavePlace)
                viewModel.savePlace(note: note, appState: appState, viewState: viewState)
            }
        )
    }
}

private struct PhoneNumberButton: View {
    var phoneNumber: String

    var body: some View {
        Button {
            if let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: " ", with: ""))") {
                UIApplication.shared.open(url)
            }
        } label: {
            VStack {
                Image(systemName: "phone.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                Text("Call")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 70, height: 75)
            .foregroundColor(.blue)
            .background(Color("foreground").opacity(0.1))
            .cornerRadius(5)
        }
    }
}

private struct WebsiteButton: View {
    var url: URL

    var body: some View {
        Button {
            UIApplication.shared.open(url)
        } label: {
            VStack {
                Image(systemName: "globe")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                Text("Website")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 70, height: 75)
            .foregroundColor(.blue)
            .background(Color("foreground").opacity(0.1))
            .cornerRadius(5)
        }
    }
}

private struct OpenInMapsButton: View {
    @ObservedObject var viewModel: PlaceDetailsViewModel

    var body: some View {
        Button {
            viewModel.openInMaps()
        } label: {
            VStack {
                Image(systemName: "arrow.up.right.square")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30)
                Text("Maps")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(width: 70, height: 75)
            .foregroundColor(.blue)
            .background(Color("foreground").opacity(0.1))
            .cornerRadius(5)
        }
    }
}

private struct PostCarousel: View {
    @StateObject var page: Page = .first()

    var text: String
    var posts: [Post]

    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 15))
                .bold()
            Spacer()
        }

        Pager(page: page, data: posts) { post in
            PostPage(post: post)
                .contentShape(Rectangle())
        }
        .padding(10)
        .alignment(.start)
        .sensitivity(.custom(0.10))
        .pagingPriority(.high)
        .frame(height: 120)
    }
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

    @Published var isStale = false

    @Published var muxedPlaceDetails: MuxedPlaceDetails? {
        didSet {
            DispatchQueue.main.async {
                self.isStale = false
            }
        }
    }

    var mkMapItem: MKMapItem? { muxedPlaceDetails?.mkMapItem }
    var details: GetPlaceDetailsResponse? { muxedPlaceDetails?.details }

    var isSaved: Bool {
        details?.mySave != nil
    }

    var isPosted: Bool {
        details?.myPost != nil
    }

    var phoneNumber: String? {
        mkMapItem?.phoneNumber
    }

    var website: URL? {
        mkMapItem?.url
    }

    // MARK: - Initialization
    private var mapListener = PostPlaceListener()

    func initialize(appState: AppState, viewState: GlobalViewState) {
        createPostVM.onCreate = { [weak self] post in
            if self?.muxedPlaceDetails?.details != nil {
                self?.muxedPlaceDetails?.details?.myPost = post
            } else {
                self?.muxedPlaceDetails?.details = .init(place: post.place, myPost: post)
            }
        }
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
            self.isStale = false
            return
        }
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
        if let post = details?.myPost {
            createPostVM.initAsEditor(post)
        } else if let place = place {
            createPostVM.selectPlace(place: place)
        } else if let mapItem = mkMapItem {
            createPostVM.selectPlace(place: mapItem)
        }
        showCreatePost = true
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
    var place: Place? {
        details?.place
    }

    var name: String {
        place?.name ?? mkMapItem?.name ?? ""
    }

    var category: String? {
        place?.category ?? mkMapItem?.pointOfInterestCategory?.toString()
    }

    var latitude: Double {
        place?.location.latitude ?? mkMapItem?.placemark.coordinate.latitude ?? 0
    }

    var longitude: Double {
        place?.location.longitude ?? mkMapItem?.placemark.coordinate.longitude ?? 0
    }

    var communityPosts: [Post] {
        details?.communityPosts ?? []
    }

    var featuredPosts: [Post] {
        details?.featuredPosts ?? []
    }

    var followingPosts: [Post] {
        details?.followingPosts ?? []
    }

    var address: String {
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

extension MKPointOfInterestCategory {
    func toString() -> String {
        return self.rawValue.replacingOccurrences(of: "MKPOICategory", with: "")
    }
}
