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
import CoreLocation


class LocationAnnotationView: MKAnnotationView {
    
    // MARK: Initialization
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        frame = CGRect(x: 0, y: 0, width: 45, height: 45)
        centerOffset = CGPoint(x: 0, y: -frame.size.height / 2)
        collisionMode = .circle
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var annotation: MKAnnotation? {
        didSet {
            if let annotation = annotation, let placeAnnotation = annotation as? PlaceAnnotation {
                setupUI(for: placeAnnotation.pin)
            }
        }
    }
    
    // MARK: Setup
    
    private func setupUI(for pin: MapPlace) {
        subviews.forEach({ $0.removeFromSuperview() })
        backgroundColor = .clear
        
        let view = UIImageView(image: UIImage(named: "pin")?.withRenderingMode(.alwaysTemplate))
        view.tintColor = UIColor(named: pin.icon.category?.lowercased() ?? "lightgray")
        view.frame = bounds
        addSubview(view)
        var image: UIImageView
        if let url = pin.icon.iconUrl {
            image = UIImageView()
            let transformer = SDImageResizingTransformer(size: CGSize(width: 100, height: 100), scaleMode: .fill)
            image.sd_setImage(
                with: URL(string: url),
                placeholderImage: UIImage(systemName: "person.crop.circle"),
                context: [.imageTransformer: transformer])
            image.backgroundColor = .white
            image.contentMode = .scaleAspectFill;
            image.frame = CGRect(x: 0, y: 0, width: 35, height: 35).offsetBy(dx: 5, dy: 2.25)
            image.layer.cornerRadius = 17.5
            image.layer.masksToBounds = true
        } else {
            image = UIImageView(image: UIImage(systemName: "person.crop.circle"))
            image.tintColor = .gray
            image.backgroundColor = .white
            image.frame = CGRect(x: 0, y: 0, width: 35, height: 35).offsetBy(dx: 5, dy: 2.25)
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
            badge.font = .systemFont(ofSize: 12)
            badge.sizeToFit()
            badge.frame = badge.frame.offsetBy(dx: self.frame.width - badge.frame.width, dy: 0)
            badge.layer.cornerRadius = min(badge.frame.height, badge.frame.width) / 2
            
            view.addSubview(badge)
        }
    }
}

class PinClusterAnnotationView: MKAnnotationView {
    static let clusteringIdentifier = "pinCluster"
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        collisionMode = .circle
        updateView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var annotation: MKAnnotation? {
        didSet {
            updateView()
        }
    }
    
    func updateView() {
        if let clusterAnnotation = annotation as? MKClusterAnnotation {
            self.image = image(count: clusterAnnotation.memberAnnotations.count)
        } else {
            self.image = image(count: 1)
        }
    }
    
    func image(count: Int) -> UIImage {
        let bounds = CGRect(origin: .zero, size: CGSize(width: 40, height: 40))
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { _ in
            UIColor.orange.setFill()
            UIBezierPath(ovalIn: bounds).fill()
            
            UIColor.init(white: 1, alpha: 0.9).setFill()
            UIBezierPath.init(ovalIn: bounds.insetBy(dx: 4, dy: 4)).fill()
            
            let attributes: [NSAttributedString.Key : Any] = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14) as Any,
            ]
            
            let text: NSString = NSString(string: "\(count)")
            let size = text.size(withAttributes: attributes)
            let origin = CGPoint(x: bounds.midX - size.width / 2, y: bounds.midY - size.height / 2)
            let rect = CGRect(origin: origin, size: size)
            text.draw(in: rect, withAttributes: attributes)
        }
    }
}

class PinMapView: MKMapView {
    var placeAnnotations: [PlaceAnnotation]
    var clusteringEnabled: Bool
    
    init(clusteringEnabled: Bool) {
        self.placeAnnotations = []
        self.clusteringEnabled = clusteringEnabled
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


struct MapKitView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedPin: PlaceAnnotation?
    var clusteringEnabled: Bool
    var annotations: [PlaceAnnotation]
    var images: [String: Data] = [:]
    
    func makeUIView(context: Context) -> PinMapView {
        let mapView: PinMapView = PinMapView(clusteringEnabled: clusteringEnabled)
        mapView.placeAnnotations = annotations
        mapView.tintAdjustmentMode = .normal
        mapView.tintColor = .systemBlue
        mapView.showsUserLocation = true
        mapView.register(LocationAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(PinClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ view: PinMapView, context: Context) {
        if view.clusteringEnabled != clusteringEnabled {
            view.clusteringEnabled = clusteringEnabled
            view.removeAnnotations(view.annotations)
            view.addAnnotations(annotations)
        }
        if !view.placeAnnotations.elementsEqual(annotations) {
            let toRemove = view.placeAnnotations.filter({ annotation in
                return !annotations.contains(annotation)
            })
            let toAdd = annotations.filter({ annotation in
                return !view.placeAnnotations.contains { $0 == annotation }
            })
            view.addAnnotations(toAdd)
            view.removeAnnotations(toRemove)
            view.placeAnnotations = annotations
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
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? PlaceAnnotation else {
                return nil
            }
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
            /// mapView should always be a PinMapView
            let clusteringEnabled = (mapView as? PinMapView)?.clusteringEnabled ?? true
            
            if view == nil {
                view = LocationAnnotationView(
                    annotation: annotation,
                    reuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
            }
            if clusteringEnabled {
                view?.clusteringIdentifier = clusteringEnabled ? MKMapViewDefaultClusterAnnotationViewReuseIdentifier : MKMapViewDefaultAnnotationViewReuseIdentifier
            }
            view?.annotation = annotation
            view?.zPriority = MKAnnotationViewZPriority(rawValue: MKAnnotationViewZPriority.RawValue(annotation.zIndex))
            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? PlaceAnnotation {
                parent.selectedPin = annotation
                mapView.deselectAnnotation(annotation, animated: false)
            } else if let annotation = view.annotation as? MKClusterAnnotation {
                mapView.showAnnotations(annotation.memberAnnotations, animated: true)
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        }
    }
}


struct MapSearch: View {
    @ObservedObject var mapViewModel: MapViewModel
    @StateObject var locationSearch: LocationSearch = LocationSearch()
    @State private var lastSearched: String? = nil
    
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
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                if locationSearch.searchQuery.count > 0 {
                    List(locationSearch.completions) { completion in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(completion.title)
                                    .foregroundColor(Color("foreground"))
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
                        .listRowBackground(Color("background"))
                    }
                    .listStyle(PlainListStyle())
                    .onAppear {
                        mapViewModel.modalState = .invisible
                    }
                    .padding(.top, 100)
                    .background(Color("background"))
                }
                Spacer()
            }
            
            VStack(spacing: 0) {
                MapSearchBar(
                    text: $locationSearch.searchQuery,
                    placeholder: "Search places"
                )
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .padding(.bottom, 15)
                Spacer()
            }
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
                    .font(.system(size: 16))
                Text(ViewPlace<ViewMKMapItemVM>.getAddress(placemark: place.placemark))
                    .font(.system(size: 14))
            }
            Spacer()
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

fileprivate struct SearchResultsView: View {
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
    }
}

fileprivate struct SelectedSearchResult: View {
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
            ViewPlace(viewPlaceVM: ViewMKMapItemVM(mapItem: place))
        }
        .frame(maxHeight: .infinity)
        .background(Color("background"))
    }
}

fileprivate struct ClusterToggleButton: View {
    
    @Binding var clusteringEnabled: Bool
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation {
                clusteringEnabled.toggle()
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color("background"))
                    .frame(width: 55, height: 55)
                    .contentShape(Circle())
                    .shadow(radius: 3)
                Circle()
                    .strokeBorder(Color("background"), lineWidth: 2)
                    .background(Circle().foregroundColor(Color("lodging")))
                    .frame(width: 20, height: 20)
                    .offset(x: clusteringEnabled ? -4 : -12)
                Circle()
                    .strokeBorder(Color("background"), lineWidth: 2)
                    .background(Circle().foregroundColor(Color("shopping")))
                    .frame(width: 20, height: 20)
                    .offset(x: clusteringEnabled ? 0 : 0)
                Circle()
                    .strokeBorder(Color("background"), lineWidth: 2)
                    .background(Circle().foregroundColor(Color("attraction")))
                    .frame(width: 20, height: 20)
                    .offset(x: clusteringEnabled ? 4 : 12)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

fileprivate struct CurrentLocationButton: View {
    @Binding var region: MKCoordinateRegion
    
    var locationManager: CLLocationManager
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation {
                if let location = locationManager.location {
                    region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                }
            }
        }) {
            ZStack {
                Image(systemName: "location.fill")
                    .foregroundColor(Color("attraction"))
                    .font(.system(size: 24))
                    .frame(width: 55, height: 55)
                    .background(Color("background"))
                    .cornerRadius(27.5)
                    .contentShape(Circle())
            }
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(radius: 3)
    }
}

fileprivate struct ButtonContainer<Content>: View where Content: View {
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                content()
            }
        }
    }
}

struct MapView: View {
    let locationManager = CLLocationManager()
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState

    @ObservedObject var localSettings: LocalSettings
    @StateObject var mapViewModel = MapViewModel()
    
    @State private var initialized = false
    @State private var region = MapViewModel.defaultRegion
    
    var preselectedPlace: Place?
    
    var body: some View {
        ZStack {
            MapKitView(
                region: $region,
                selectedPin: $mapViewModel.presentedPin,
                clusteringEnabled: localSettings.clusteringEnabled,
                annotations: mapViewModel.mapAnnotations
            )
            .onTapGesture {
                hideKeyboard()
                mapViewModel.modalState = .invisible
            }
            
            if preselectedPlace == nil {
                // Only show these if there is no preselected post
                ButtonContainer {
                    VStack(spacing: 10) {
                        CurrentLocationButton(region: $region, locationManager: locationManager)
                        ClusterToggleButton(clusteringEnabled: $localSettings.clusteringEnabled)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
                MapSearch(mapViewModel: mapViewModel)
            }
            
            GeometryReader { geometry in
                SnapDrawer(state: $mapViewModel.modalState,
                           large: 320,
                           tiny: 100,
                           allowInvisible: true,
                           background: Color("background")) { state in
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
                                .onAppear {
                                    let mapItemRegion = place.placemark.region as? CLCircularRegion
                                    let radiusMeters = mapItemRegion?.radius ?? 120
                                    let radiusDegrees = radiusMeters / 111111 // Approximate
                                    region = MKCoordinateRegion(
                                        center: CLLocationCoordinate2D(
                                            latitude: place.placemark.coordinate.latitude - 0.00025,
                                            longitude: place.placemark.coordinate.longitude),
                                        span: MKCoordinateSpan(
                                            latitudeDelta: radiusDegrees,
                                            longitudeDelta: radiusDegrees))
                                }
                            }
                        }
                    } else if let placeAnnotation = mapViewModel.presentedPin {
                        ViewPlace(viewPlaceVM: ViewPinVM(pin: placeAnnotation.pin))
                            .frame(maxHeight: .infinity)
                    } else {
                        EmptyView()
                    }
                }
                .foregroundColor(Color("foreground"))
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .edgesIgnoringSafeArea(.top)
        .appear {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            if !initialized {
                if preselectedPlace == nil, let location = locationManager.location {
                    DispatchQueue.main.async {
                        self.region = MKCoordinateRegion(
                            center: location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
                        )
                    }
                }
                if let place = preselectedPlace {
                    region.center = CLLocationCoordinate2D(latitude: place.location.latitude, longitude: place.location.longitude)
                    region.span = MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
                    mapViewModel.presentPreselectedPlace(place: place, appState: appState, globalViewState: globalViewState)
                }
                initialized = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                mapViewModel.startRefreshingMap(
                    appState: appState,
                    globalViewState: globalViewState,
                    preselectedPlace: preselectedPlace
                )
            }
        }
        .disappear {
            mapViewModel.stopRefreshingMap()
        }
        .accentColor(.blue)
    }
}
