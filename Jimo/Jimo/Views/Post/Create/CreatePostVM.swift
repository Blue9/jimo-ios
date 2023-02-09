//
//  CreatePostVM.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/10/21.
//

import SwiftUI
import Combine
import MapKit

enum CreatePostActiveSheet: String, Identifiable {
    case placeSearch, imagePicker

    var id: String {
        self.rawValue
    }
}

enum CreatePostImage {
    case uiImage(UIImage)
    case webImage(ImageId, String)

    var uiImage: UIImage? {
        switch self {
        case .uiImage(let image):
            return image
        case .webImage:
            return nil
        }
    }

    var imageId: ImageId? {
        switch self {
        case .uiImage:
            return nil
        case .webImage(let imageId, _):
            return imageId
        }
    }

    var url: String? {
        switch self {
        case .uiImage:
            return nil
        case .webImage(_, let url):
            return url
        }
    }
}

enum CreateOrEdit: Equatable {
    case create, edit(PostId)

    var title: String {
        switch self {
        case .create:
            return "Post a place"
        case .edit:
            return "Update"
        }
    }

    func action(appState: AppState) -> ((CreatePostRequest) -> AnyPublisher<Post, APIError>) {
        switch self {
        case .create:
            return appState.createPost
        case .edit(let postId):
            return { request in appState.updatePost(postId, request) }
        }
    }
}

enum Status: Equatable, Hashable {
    case drafting, loading, success(Post)
}

class CreatePostVM: ObservableObject {
    var createOrEdit: CreateOrEdit

    @Published var activeSheet: CreatePostActiveSheet?
    /// Post data
    @Published var name: String?
    @Published var maybeCreatePlaceCoord: CLLocationCoordinate2D?
    @Published var maybeCreatePlaceRegion: Region?
    @Published var previewRegion: MKCoordinateRegion?
    @Published var additionalPlaceData: AdditionalPlaceDataRequest?

    @Published var category: String?
    @Published var content: String = ""
    @Published var stars: Int?
    @Published var image: CreatePostImage?

    /// Only used when editing
    @Published var placeId: String?

    /// View information
    @Published var showError = false
    @Published var errorMessage = ""

    @Published var postingStatus = Status.drafting

    var onCreate: ((Post) -> Void)?

    var uiImageBinding: Binding<UIImage?> {
        Binding<UIImage?>(
            get: { self.image?.uiImage },
            set: {
                if let image = $0 {
                    self.image = .uiImage(image)
                } else {
                    self.image = nil
                }
            }
        )
    }

    var cancelBag: Set<AnyCancellable> = Set()

    /// Create post
    init() {
        self.createOrEdit = .create
    }

    /// Edit post
    func initAsEditor(_ post: Post) {
        self.createOrEdit = .edit(post.id)
        self.name = post.place.name
        self.category = post.category
        self.content = post.content
        self.stars = post.stars
        self.previewRegion = MKCoordinateRegion(
            center: post.place.location.coordinate(),
            span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        )
        if let imageId = post.imageId, let imageUrl = post.imageUrl {
            self.image = .webImage(imageId, imageUrl)
        } else {
            self.image = nil
        }
        self.placeId = post.place.placeId
    }

    var maybeCreatePlaceRequest: MaybeCreatePlaceRequest? {
        guard let name = name, let location = maybeCreatePlaceCoord else {
            return nil
        }
        return MaybeCreatePlaceRequest(
            name: name,
            location: Location(coord: location),
            region: maybeCreatePlaceRegion,
            additionalData: additionalPlaceData
        )
    }

    func selectPlace(place: MKMapItem) {
        name = place.name
        placeId = nil
        maybeCreatePlaceCoord = place.placemark.coordinate
        maybeCreatePlaceRegion = place.circularRegion
        previewRegion = toPreviewRegion(place)
        additionalPlaceData = AdditionalPlaceDataRequest(place)
    }

    func selectPlace(place: Place) {
        name = place.name
        placeId = place.id
        previewRegion = MKCoordinateRegion(
            center: place.location.coordinate(),
            span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4)
        )
        maybeCreatePlaceCoord = nil
        maybeCreatePlaceRegion = nil
        additionalPlaceData = nil
    }

    func resetAll() {
        self.resetPlace()
        self.createOrEdit = .create
        self.category = nil
        self.content = ""
        self.stars = nil
        self.image = nil
        self.placeId = nil
        self.showError = false
        self.errorMessage = ""
        self.postingStatus = .drafting
        self.onCreate = nil
        self.cancelBag.removeAll(keepingCapacity: true)
    }

    func resetPlace() {
        name = nil
        placeId = nil
        maybeCreatePlaceCoord = nil
        maybeCreatePlaceRegion = nil
        previewRegion = nil
        additionalPlaceData = nil
    }

    func createPost(appState: AppState) {
        guard maybeCreatePlaceRequest != nil || placeId != nil else {
            errorMessage = "Location is required"
            showError = true
            return
        }
        guard let category = category else {
            errorMessage = "Category is required"
            showError = true
            return
        }
        let content = self.content
        self.postingStatus = .loading
        buildRequest(
            appState: appState,
            placeId: placeId,
            place: placeId == nil ? maybeCreatePlaceRequest : nil,
            category: category,
            content: content,
            stars: stars,
            image: image
        )
        .sink { completion in
            if case let .failure(error) = completion {
                print("Error when creating post", error)
                if case let .requestError(maybeErrors) = error,
                   let errors = maybeErrors,
                   let first = errors.first {
                    self.errorMessage = first.value
                } else {
                    self.errorMessage = "Could not save place"
                }
                self.showError = true
                self.postingStatus = .drafting
            }
        } receiveValue: { post in
            self.postingStatus = .success(post)
            self.onCreate?(post)
        }.store(in: &cancelBag)
    }

    private func buildRequest(
        appState: AppState,
        placeId: PlaceId?,
        place: MaybeCreatePlaceRequest?,
        category: String,
        content: String,
        stars: Int?,
        image: CreatePostImage?
    ) -> AnyPublisher<Post, APIError> {
        let action = self.createOrEdit.action(appState: appState)
        guard case let .uiImage(imageToUpload) = image else {
            return action(
                CreatePostRequest(
                    placeId: placeId,
                    place: place,
                    category: category,
                    content: content,
                    stars: stars,
                    imageId: image?.imageId)
            )
        }
        return tryUploadImage(appState: appState, image: imageToUpload) { imageId in
            action(
                CreatePostRequest(
                    placeId: placeId,
                    place: place,
                    category: category,
                    content: content,
                    stars: stars,
                    imageId: imageId
                )
            )
        }
    }

    private func tryUploadImage<R>(
        appState: AppState,
        image: UIImage,
        then: @escaping (ImageId) -> AnyPublisher<R, APIError>
    ) -> AnyPublisher<R, APIError> {
        appState
            .uploadImageAndGetId(image: image)
            .catch({ error -> AnyPublisher<ImageId, APIError> in
                print("Error when uploading image", error)
                if case let .requestError(error) = error,
                   let first = error?.first {
                    self.errorMessage = first.value
                    self.showError = true
                } else {
                    self.errorMessage = "Could not upload image."
                    self.showError = true
                }
                return Empty().eraseToAnyPublisher()
            }).flatMap({ imageId -> AnyPublisher<R, APIError> in
                then(imageId)
            }).eraseToAnyPublisher()
    }

    private func toPreviewRegion(_ mapItem: MKMapItem) -> MKCoordinateRegion {
        var span: CLLocationDegrees = 4  // Default span = 4
        if let region = mapItem.placemark.region as? CLCircularRegion {
            span = min(region.radius * 10, 200000) / 111111
        }
        return MKCoordinateRegion(
            center: mapItem.placemark.coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: span,
                longitudeDelta: span
            )
        )
    }
}
