//
//  MapSnapshotView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 9/22/21.
//

import SwiftUI
import MapKit

class MapSnapshotCacheKey: NSObject {
    var colorScheme: ColorScheme

    var place: Place
    var category: String
    var profilePictureUrl: String?
    var span: CLLocationDegrees
    var width: CGFloat
    var height: CGFloat?

    init(_ colorScheme: ColorScheme, _ post: Post, _ span: CLLocationDegrees, _ width: CGFloat, _ height: CGFloat?) {
        self.colorScheme = colorScheme
        self.place = post.place
        self.category = post.category
        self.profilePictureUrl = post.user.profilePictureUrl
        self.span = span
        self.width = width
        self.height = height
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let o = object as? MapSnapshotCacheKey else {
            return false
        }
        return place == o.place
            && category == o.category
            && profilePictureUrl == o.profilePictureUrl
            && span == o.span
            && width == o.width
            && height == o.height
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(place)
        hasher.combine(category)
        hasher.combine(profilePictureUrl)
        hasher.combine(span)
        hasher.combine(width)
        hasher.combine(height)
        return hasher.finalize()
    }
}

private let cache = NSCache<MapSnapshotCacheKey, UIImage>()

// From https://codakuma.com/swiftui-static-maps/
struct MapSnapshotView: View {
    @Environment(\.colorScheme) var colorScheme

    let post: Post
    var span: CLLocationDegrees = 0.005
    var width: CGFloat
    var height: CGFloat?

    @State private var snapshotImage: UIImage?

    var cacheKey: MapSnapshotCacheKey {
        MapSnapshotCacheKey(colorScheme, post, span, width, height)
    }

    func generateSnapshot(width: CGFloat, height: CGFloat) {
        guard snapshotImage == nil else {
            return
        }
        if let image = cache.object(forKey: cacheKey) {
            self.snapshotImage = image
            return
        }
        // The region the map should display.
        let region = MKCoordinateRegion(
            center: self.post.place.location.coordinate(),
            span: MKCoordinateSpan(
                latitudeDelta: self.span,
                longitudeDelta: self.span
            )
        )

        // Map options.
        let mapOptions = MKMapSnapshotter.Options()
        mapOptions.region = region
        mapOptions.size = CGSize(width: width, height: height)
        mapOptions.showsBuildings = false

        // Create the snapshotter and run it.
        let snapshotter = MKMapSnapshotter(options: mapOptions)
        snapshotter.start { (snapshotOrNil, errorOrNil) in
            if let error = errorOrNil {
                print(error)
                return
            }
            if let snapshot = snapshotOrNil {
                cache.setObject(snapshot.image, forKey: cacheKey)
                self.snapshotImage = snapshot.image
            }
        }
    }

    var body: some View {
        ZStack {
            Group {
                if let image = snapshotImage {
                    Image(uiImage: image)
                } else {
                    Color("secondary")
                }
            }

            Circle()
                .fill()
                .frame(width: 40, height: 40)
                .foregroundColor(Color(post.category))

            URLImage(
                url: post.user.profilePictureUrl,
                loading: Image(systemName: "person.crop.circle"),
                thumbnail: true
            )
                .foregroundColor(.gray)
                .frame(width: 35, height: 35)
                .background(Color.white)
                .cornerRadius(17.5)
        }
        .onAppear {
            generateSnapshot(width: width, height: height ?? width)
        }
        .onChange(of: colorScheme) { _ in
            self.snapshotImage = nil
            generateSnapshot(width: width, height: height ?? width)
        }
    }
}
