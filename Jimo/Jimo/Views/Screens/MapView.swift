//
//  MapView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/6/20.
//

import MapKit
import SwiftUI
import Combine
import SDWebImage


final class LocationAnnotationView: MKAnnotationView {
    
    // MARK: Initialization
    
    private var post: Post
    
    init(annotation: PostAnnotation, reuseIdentifier: String) {
        self.post = annotation.post
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 60, height: 60)
        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)
        setupUI()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    
    private func setupUI() {
        backgroundColor = .clear

        let view = UIImageView(image: UIImage(named: "pin")?.withRenderingMode(.alwaysTemplate))
        view.tintColor = UIColor(named: post.category.lowercased())
        view.frame = bounds
        addSubview(view)
        var image: UIImageView
        if let url = post.user.profilePictureUrl {
            image = UIImageView()
            image.sd_setImage(
                with: URL(string: url),
                placeholderImage: UIImage(systemName: "person.crop.circle"))
            image.frame = CGRect(x: 0, y: 0, width: 42, height: 42).offsetBy(dx: 9, dy: 5.75)
            image.layer.cornerRadius = 21
            image.layer.masksToBounds = true
        } else {
            image = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
            image.tintColor = UIColor(named: post.category.lowercased())
            image.backgroundColor = .white
            image.frame = CGRect(x: 0, y: 0, width: 42, height: 42).offsetBy(dx: 9, dy: 5.75)
            image.layer.cornerRadius = 21
            image.layer.masksToBounds = true
        }
        view.addSubview(image)
    }
}


struct MapKitView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedPost: Post?
    @Binding var showPost: Bool
    var annotations: [PostAnnotation]
    var images: [String: Data] = [:]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        if !view.annotations.map({ $0 as? PostAnnotation }).elementsEqual(annotations) {
            view.removeAnnotations(view.annotations)
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
            
            let view = LocationAnnotationView(
                annotation: annotation,
                reuseIdentifier: identifier)
            view.zPriority = MKAnnotationViewZPriority(rawValue: MKAnnotationViewZPriority.RawValue(annotation.zIndex))
            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            let annotation = view.annotation as! PostAnnotation
            parent.showPost = true
            parent.selectedPost = annotation.post
            mapView.deselectAnnotation(annotation, animated: false)
        }
    }
}


struct MapSearch: View {
    @StateObject var locationSearch: LocationSearch = LocationSearch()
    @State var query: String = ""
    
    @State var lastSearched: String? = nil
    
    func search(completion: MKLocalSearchCompletion) {
        lastSearched = completion.title
        let localSearch = MKLocalSearch(request: .init(completion: completion))
        localSearch.start { (response, error) in
            if let places = response?.mapItems {
                locationSearch.searchQuery = ""
                hideKeyboard()
                print(places)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(
                text: $locationSearch.searchQuery,
                minimal: true,
                placeholder: "Search places",
                textFieldColor: .init(white: 1, alpha: 0.4))
                .padding(.horizontal, 15)
                .padding(.top, 50)
                .padding(.bottom, 15)
                .background(Color.init(white: 1, opacity: 0.9))
            
            if locationSearch.searchQuery.count > 0 {
                List(locationSearch.completions) { completion in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(completion.title)
                            Text(completion.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.search(completion: completion)
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct MapView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var mapModel: MapModel
    
    @ObservedObject var mapViewModel: MapViewModel
    
    var mapAnnotations: [PostAnnotation] {
        appState.mapModel.posts
            .map({ appState.allPosts.posts[$0]! })
            .enumerated()
            .map({ PostAnnotation(post: $1, zIndex: $0) })
    }
    
    var body: some View {
        ZStack {
            MapKitView(
                region: $mapViewModel.region,
                selectedPost: $mapViewModel.presentedPost,
                showPost: $mapViewModel.presentBottomSheet,
                annotations: mapAnnotations)
                .edgesIgnoringSafeArea(.all)
            
            MapSearch()
                .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            mapViewModel.refreshMap()
        }
        .bottomSheet(isPresented: $mapViewModel.presentBottomSheet, height: 600) {
            if let post = mapViewModel.presentedPost {
                ViewPlace(placeViewModel: PlaceViewModel(place: post.place))
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
