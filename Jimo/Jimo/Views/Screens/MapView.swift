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


class LocationAnnotationView: MKAnnotationView {
    
    // MARK: Initialization
    
    private var pin: MapPlace
    
    init(annotation: PlaceAnnotation, reuseIdentifier: String) {
        self.pin = annotation.pin
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 50, height: 50)
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
        view.tintColor = UIColor(named: pin.icon.category?.lowercased() ?? "lightgray")
        view.frame = bounds
        addSubview(view)
        var image: UIImageView
        if let url = pin.icon.iconUrl {
            image = UIImageView()
            image.sd_setImage(
                with: URL(string: url),
                placeholderImage: UIImage(systemName: "person.crop.circle"))
            image.backgroundColor = .white
            image.contentMode = .scaleAspectFill;
            image.frame = CGRect(x: 0, y: 0, width: 35, height: 35).offsetBy(dx: 7.5, dy: 4.75)
            image.layer.cornerRadius = 17.5
            image.layer.masksToBounds = true
        } else {
            image = UIImageView(image: UIImage(systemName: "person.crop.circle"))
            image.tintColor = .gray
            image.backgroundColor = .white
            image.frame = CGRect(x: 0, y: 0, width: 35, height: 35).offsetBy(dx: 7.5, dy: 4.75)
            image.layer.cornerRadius = 17.5
            image.layer.masksToBounds = true
        }
        view.addSubview(image)
        
        if pin.icon.numMutualPosts > 1 {
            let badge = UITextView()
            badge.textContainerInset = .init(top: 0, left: 0, bottom: 0, right: 0)
            badge.backgroundColor = UIColor(red: 0.11, green: 0.51, blue: 0.95, alpha: 1)
            badge.layer.masksToBounds = true
            badge.textColor = .white
            badge.textAlignment = .center
            badge.text = String(pin.icon.numMutualPosts)
            badge.font = UIFont.init(name: Poppins.regular, size: 12)
            badge.sizeToFit()
            badge.frame = badge.frame.offsetBy(dx: self.frame.width - badge.frame.width, dy: 0)
            badge.layer.cornerRadius = min(badge.frame.height, badge.frame.width) / 2
            
            view.addSubview(badge)
        }
    }
}


struct MapKitView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedPin: PlaceAnnotation?
    var annotations: [PlaceAnnotation]
    var images: [String: Data] = [:]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.tintAdjustmentMode = .normal
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        if !view.annotations.map({ $0 as? PlaceAnnotation }).elementsEqual(annotations) {
            let toRemove = view.annotations.filter({ annotation in
                let placeAnnotation = annotation as? PlaceAnnotation
                return placeAnnotation == nil || !annotations.contains(placeAnnotation!)
            })
            let toAdd = annotations.filter({ annotation in
                return !view.annotations.contains { $0 as? PlaceAnnotation == annotation }
            })
            view.addAnnotations(toAdd)
            view.removeAnnotations(toRemove)
        }
        if view.region != region {
            view.setRegion(region, animated: true)
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
            let annotation = annotation as! PlaceAnnotation
            let identifier = "Placemark"
            
            let view = LocationAnnotationView(
                annotation: annotation,
                reuseIdentifier: identifier)
            view.zPriority = MKAnnotationViewZPriority(rawValue: MKAnnotationViewZPriority.RawValue(annotation.zIndex))
            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            let annotation = view.annotation as! PlaceAnnotation
            parent.selectedPin = annotation
            mapView.deselectAnnotation(annotation, animated: false)
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        }
    }
}


struct MapSearch: View {
    @Environment(\.backgroundColor) var backgroundColor
    @StateObject var mapViewModel: MapViewModel
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
                mapViewModel.results = places
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
                .background(backgroundColor.opacity(0.9))
            
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
                .listStyle(PlainListStyle())
                .colorMultiply(backgroundColor)
                .onAppear {
                    mapViewModel.modalState = .invisible
                }
            }
            
            Spacer()
        }
    }
}

fileprivate struct SearchResult: View {
    let place: MKMapItem
    let name: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .font(Font.custom(Poppins.medium, size: 16))
                Text(ViewPlace.getAddress(placemark: place.placemark))
                    .font(Font.custom(Poppins.regular, size: 14))
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

fileprivate struct SearchResultsView: View {
    @Environment(\.backgroundColor) var backgroundColor
    
    @Binding var selectedSearchResult: MKMapItem?
    
    let results: [MKMapItem]
    
    var body: some View {
        List(results, id: \.self) { (place: MKMapItem) in
            if let name = place.name {
                SearchResult(place: place, name: name)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            selectedSearchResult = place
                        }
                    }
            }
        }
        .listStyle(PlainListStyle())
        .colorMultiply(backgroundColor)
    }
}

fileprivate struct SelectedSearchResult: View {
    @Environment(\.backgroundColor) var backgroundColor
    
    @Binding var selectedSearchResult: MKMapItem?
    
    let place: MKMapItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "chevron.backward")
                Text("Back to search")
            }
            .padding(.horizontal)
            .padding(.top)
            .onTapGesture {
                withAnimation {
                    selectedSearchResult = nil
                }
            }
            ViewPlace(mapItem: place)
        }
        .frame(maxHeight: .infinity)
        .background(backgroundColor)
    }
}


struct MapView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.backgroundColor) var backgroundColor
    
    @ObservedObject var mapModel: MapModel
    @StateObject var mapViewModel: MapViewModel
    
    var body: some View {
        ZStack {
            MapKitView(
                region: $mapViewModel.region,
                selectedPin: $mapViewModel.presentedPin,
                annotations: mapViewModel.mapAnnotations
            )
            .onTapGesture {
                hideKeyboard()
                mapViewModel.modalState = .invisible
            }
            
            if mapViewModel.preselectedPost == nil {
                // Only show search if there is no preselected post
                MapSearch(mapViewModel: mapViewModel)
            }
            
            GeometryReader { geometry in
                SnapDrawer(state: $mapViewModel.modalState,
                           large: 400,
                           tiny: 150,
                           allowInvisible: true,
                           background: backgroundColor) { state in
                    if let results = mapViewModel.results {
                        ZStack {
                            SearchResultsView(
                                selectedSearchResult: $mapViewModel.selectedSearchResult,
                                results: results
                            )
                            
                            if let place = mapViewModel.selectedSearchResult {
                                SelectedSearchResult(
                                    selectedSearchResult: $mapViewModel.selectedSearchResult,
                                    place: place
                                )
                                .transition(.move(edge: .trailing))
                                .onAppear {
                                    mapViewModel.region.center = place.placemark.coordinate
                                    mapViewModel.region = MKCoordinateRegion(
                                        center: CLLocationCoordinate2D(
                                            latitude: place.placemark.coordinate.latitude - 0.00025,
                                            longitude: place.placemark.coordinate.longitude),
                                        span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
                                }
                            }
                        }
                    } else if let placeAnnotation = mapViewModel.presentedPin {
                        ViewPlace(place: placeAnnotation.place)
                            .id(placeAnnotation.self)
                            .frame(maxHeight: .infinity)
                    } else {
                        EmptyView()
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .appear {
            mapViewModel.startRefreshingMap()
        }
        .disappear {
            mapViewModel.stopRefreshingMap()
        }
    }
}


struct MapView_Previews: PreviewProvider {
    static let appState = AppState(apiClient: APIClient())
    static let viewState = GlobalViewState()
    
    static var previews: some View {
        MapView(mapModel: appState.mapModel, mapViewModel: MapViewModel(appState: appState, viewState: viewState))
            .environmentObject(appState)
            .environmentObject(GlobalViewState())
    }
}
