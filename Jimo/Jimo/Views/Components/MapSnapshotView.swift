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
    let post: Post
    var span: CLLocationDegrees = 0.005
    
    @State private var snapshotImage: UIImage? = nil
    
    func generateSnapshot(width: CGFloat, height: CGFloat) {
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
        mapOptions.traitCollection = UITraitCollection(userInterfaceStyle: .light)
        
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
        GeometryReader { geometry in
            Group {
                if let image = snapshotImage {
                    ZStack {
                        Image(uiImage: image)
                        
                        Image("pin")
                            .renderingMode(.template)
                            .resizable()
                            .frame(width: 45, height: 45)
                            .offset(y: -22.5)
                            .foregroundColor(Color(post.category))
                        
                        URLImage(
                            url: post.user.profilePictureUrl,
                            loading: Image(systemName: "person.crop.circle"),
                            failure: Image(systemName: "person.crop.circle"),
                            thumbnail: true
                        )
                            .foregroundColor(.gray)
                            .frame(width: 35, height: 35)
                            .background(Color.white)
                            .cornerRadius(17.5)
                            .offset(y: -25)
                    }
                } else {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ProgressView().progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }
                        Spacer()
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                }
            }
            .onAppear {
                generateSnapshot(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}
