//
//  CreatePostVM.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/10/21.
//

import SwiftUI
import Combine
import MapKit

typealias ImageUrl = String

enum CreatePostActiveSheet: String, Identifiable {
    case placeSearch, imagePicker

    var id: String {
        self.rawValue
    }
}

enum CreatePostImage: Equatable, Hashable {
    case uiImage(UIImage)
    case webImage(PostMediaItem)

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
        case .webImage(let item):
            return item.id
        }
    }

    var url: String? {
        switch self {
        case .uiImage:
            return nil
        case .webImage(let item):
            return item.url
        }
    }
}

enum CreateOrEdit: Equatable {
    case create, edit(PostId)

    var title: String {
        switch self {
        case .create:
            return "Add a place"
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
    @Published var existingImages: [PostMediaItem] = []
    @Published var uiImages: [UIImage] = []

    var images: [CreatePostImage] {
        existingImages.map { .webImage($0) } + uiImages.map { .uiImage($0) }
    }

    func removeImage(_ image: CreatePostImage) {
        switch image {
        case .uiImage(let image):
            uiImages.removeAll(where: { $0 == image })
        case .webImage(let item):
            existingImages.removeAll(where: { $0 == item })
        }
    }

    @Published var placeId: String?

    /// View information
    @Published var showError = false
    @Published var errorMessage = ""

    @Published var postingStatus = Status.drafting

    var onCreate: ((Post) -> Void)?

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
        self.existingImages = post.media ?? []
        self.uiImages = []
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
        self.uiImages = []
        self.existingImages = []
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

    @MainActor
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
        createOrUpdatePost(
            appState: appState,
            placeId: placeId,
            place: placeId == nil ? maybeCreatePlaceRequest : nil,
            category: category,
            content: content,
            stars: stars,
            images: images
        )
    }

    @MainActor
    private func createOrUpdatePost(
        appState: AppState,
        placeId: PlaceId?,
        place: MaybeCreatePlaceRequest?,
        category: String,
        content: String,
        stars: Int?,
        images: [CreatePostImage]
    ) {
        Task {
            await createOrUpdatePostAsync(
                appState: appState,
                placeId: placeId,
                place: place,
                category: category,
                content: content,
                stars: stars,
                images: images
            )
        }
    }

    @MainActor
    private func createOrUpdatePostAsync(
        appState: AppState,
        placeId: PlaceId?,
        place: MaybeCreatePlaceRequest?,
        category: String,
        content: String,
        stars: Int?,
        images: [CreatePostImage]
    ) async {
        let action = self.createOrEdit.action(appState: appState)
        do {
            var imageIds: [ImageId] = []
            for image in images {
                switch image {
                case .uiImage(let image):
                    if let imageId = await uploadImage(appState: appState, image: image) {
                        imageIds.append(imageId)
                    }
                case .webImage(let item):
                    imageIds.append(item.id)
                }
            }
            for try await post in action(
                CreatePostRequest(
                    placeId: placeId,
                    place: place,
                    category: category,
                    content: content,
                    stars: stars,
                    media: imageIds)
            ).values {
                self.postingStatus = .success(post)
                self.onCreate?(post)
            }
        } catch APIError.requestError(let error) {
            if let first = error?.first {
                self.errorMessage = first.value
            } else {
                self.errorMessage = "Could not add place"
            }
            self.showError = true
            self.postingStatus = .drafting
        } catch {
            self.errorMessage = "Could not add place"
            self.showError = true
            self.postingStatus = .drafting
        }
    }

    @MainActor
    private func uploadImage(appState: AppState, image: UIImage) async -> ImageId? {
        do {
            for try await imageId in appState.uploadImageAndGetId(image: image).values {
                return imageId
            }
        } catch APIError.requestError(let error) {
            print("Error when uploading image", error)
            if let first = error?.first {
                self.errorMessage = first.value
                self.showError = true
            }
        } catch {
            self.errorMessage = "Could not upload image."
            self.showError = true
        }
        return nil
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
