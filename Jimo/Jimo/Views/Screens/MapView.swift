//
//  MapView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import MapKit
import SwiftUI
import Combine


class PostAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let post: Post
    
    init(post: Post) {
        self.post = post
        if let location = post.customLocation {
            self.coordinate = location.coordinate()
        } else {
            self.coordinate = post.place.location.coordinate()
        }
    }
}


struct MapKitView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedPost: PostId?
    @Binding var showPost: Bool
    var annotations: [PostAnnotation]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        // TODO check each equal, count isn't accurate
        if annotations.count != view.annotations.count {
            view.removeAnnotations(annotations)
            view.addAnnotations(annotations)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapKitView

        init(_ parent: MapKitView) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            parent.region = mapView.region
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let annotation = annotation as! PostAnnotation
            let identifier = "Placemark"
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            let originalImage: UIImage = UIImage(named: "pin")!
            let image = UIImage(cgImage: originalImage.cgImage!, scale: originalImage.scale / (50 / originalImage.size.height), orientation: .up)
                .withRenderingMode(.alwaysTemplate)
                .withTintColor(.yellow)
            annotationView.image = image
            annotationView.backgroundColor = UIColor(Color(annotation.post.category.lowercased()))
            annotationView.tintColor = .red
            annotationView.centerOffset = CGPoint(x: 0, y: -25)
            // TODO ios 14 only
            annotationView.zPriority = .init(Float(annotation.post.place.name.count + annotation.post.category.count))
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            let annotation = view.annotation as! PostAnnotation
            parent.showPost = true
            parent.selectedPost = annotation.post.postId
            mapView.deselectAnnotation(annotation, animated: false)
        }
    }
}


struct MapSearch: View {
    @State var query: String = ""
    
    var body: some View {
        SearchBar(
            text: $query,
            minimal: true,
            placeholder: "Search places",
            textFieldColor: .init(white: 1, alpha: 0.4))
            .padding(.horizontal, 15)
            .padding(.top, 50)
            .padding(.bottom, 15)
    }
}

struct MapView: View {
    @EnvironmentObject var appState: AppState
    var mapModel: MapModel
    
    @ObservedObject var mapViewModel: MapViewModel
    
    var mapAnnotations: [Post] {
        mapModel.posts.map({ appState.allPosts.posts[$0]! })
    }
    
    var body: some View {
        ZStack {
            MapKitView(
                region: $mapViewModel.region,
                selectedPost: $mapViewModel.presentedPost,
                showPost: $mapViewModel.presentBottomSheet,
                annotations: mapViewModel.annotations)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                MapSearch()
                    .background(Color.init(white: 1, opacity: 0.9))
                Spacer()
            }
            .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            mapViewModel.refreshMap()
        }
        .bottomSheet(isPresented: $mapViewModel.presentBottomSheet, height: 600) {
            if let postId = mapViewModel.presentedPost {
                ViewPost(postId: postId)
            }
        }
    }
}

struct MapView_Previews: PreviewProvider {
    static let appState = AppState(apiClient: APIClient())
    
    static var previews: some View {
        MapView(mapModel: appState.mapModel, mapViewModel: MapViewModel(appState: appState))
            .environmentObject(appState)
    }
}
