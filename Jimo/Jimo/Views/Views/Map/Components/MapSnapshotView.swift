//
//  MapSnapshotView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 9/22/21.
//

import SwiftUI
import MapKit

// From https://codakuma.com/swiftui-static-maps/
struct MapSnapshotView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let post: Post
    var span: CLLocationDegrees = 0.005
    var width: CGFloat
    var height: CGFloat?
    
    @State private var snapshotImage: UIImage? = nil
    
    func generateSnapshot(width: CGFloat, height: CGFloat) {
        guard snapshotImage == nil else {
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
        .onChange(of: colorScheme) { colorScheme in
            self.snapshotImage = nil
            generateSnapshot(width: width, height: height ?? width)
        }
    }
}
