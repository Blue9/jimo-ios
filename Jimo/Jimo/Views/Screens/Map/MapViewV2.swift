//
//  MapViewV2.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/7/22.
//

import SwiftUI
import MapKit
import BottomSheet
import SwiftUIPager


class RegionWrapper: ObservableObject {
    var _region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37, longitude: -96),
        span: MKCoordinateSpan(latitudeDelta: 85, longitudeDelta: 61))
    
    var region: Binding<MKCoordinateRegion> {
        Binding(
            get: { self._region },
            set: { self._region = $0 }
        )
    }
    
    @Published var trigger = false
}

struct MapBottomSheet: View {
    @ObservedObject var mapViewModel: MapViewModelV2
    
    @Binding var bottomSheetPosition: MapSheetPosition
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                UserFilter(mapViewModel: mapViewModel).padding(.trailing)
            }
            .padding(.top, 10)
        }
        .padding(.leading)
    }
}

struct MapBottomSheetHeader: View {
    @ObservedObject var mapViewModel: MapViewModelV2
    
    @Binding var searchFieldActive: Bool
    @Binding var bottomSheetPosition: MapSheetPosition
    
    @Binding var showHelpAlert: Bool
    
    var body: some View {
        HStack {
            SearchField(text: $mapViewModel.filterUsersQuery, isActive: $searchFieldActive, placeholder: "Search friends", onCommit: {})
                .ignoresSafeArea(.keyboard, edges: .all)
                .onChange(of: searchFieldActive) { isActive in
                    withAnimation {
                        bottomSheetPosition = isActive ? .top : .middle
                    }
                }
            
            if !searchFieldActive {
                Button(action: { showHelpAlert.toggle() }) {
                    Image(systemName: "info.circle")
                        .opacity(0.8)
                        .font(.system(size: 22, weight: .light))
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
            }
        }
    }
}

enum MapSheetPosition: CGFloat, CaseIterable {
    case top = 0.975, middle = 0.4, bottom = 0.2, hidden = 0
}

struct MapViewV2: View {
    @AppStorage("firstVisit") var shouldShowHelpInfo = true
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    let geocoder = CLGeocoder()
    
    @StateObject var mapViewModel = MapViewModelV2()
    @StateObject var createPostVM = CreatePostVM()
    @StateObject var regionWrapper = RegionWrapper()
    @State var activePinIndex: Page = .first()
    
    @State var selectedPin: MapPlace?
    
    @State var showCreatePost = false
    
    @State var bottomSheetPosition: MapSheetPosition = .bottom
    @State private var searchFieldActive = false
    
    @State private var initialized = false
    @State private var finishedPreselectingPost = false
    
    @State private var showHelpAlert = false
    
    var preselectedPost: Post?
    
    var quickViewDisplayed: Bool {
        bottomSheetPosition == .hidden
    }
    
    @ViewBuilder var mapOverlay: some View {
        VStack(spacing: 0) {
            if !quickViewDisplayed {
                CategoryFilter(selectedCategories: $mapViewModel.selectedCategories)
            }
            HStack {
                Spacer()
                CurrentLocationButton(regionWrapper: regionWrapper, locationManager: mapViewModel.locationManager)
                    .padding(.horizontal)
            }
            Spacer()
        }
        .animation(.easeInOut, value: quickViewDisplayed)
    }
    
    private func moveToPin(pin: MapPlace) {
        regionWrapper.region.center.wrappedValue = pin.place.location.coordinate()
        if regionWrapper.region.span.longitudeDelta.wrappedValue > 0.2 {
            regionWrapper.region.span.wrappedValue = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        }
        regionWrapper.trigger.toggle()
        bottomSheetPosition = .hidden
    }
    
    private func updatePage(pin: MapPlace) {
        if let i = mapViewModel.mapPins.pins.firstIndex(of: pin) {
            activePinIndex = .withIndex(i)
        }
    }
    
    private func updateSelectedPin(index: Int) {
        if index < mapViewModel.mapPins.pins.count {
            selectedPin = mapViewModel.mapPins.pins[index]
        } else {
            // Should never get here but just in case
            print("WARNING INDEX \(index) OUT OF BOUNDS \(mapViewModel.mapPins.pins.count)")
        }
    }
    
    private func deselectPin() {
        bottomSheetPosition = .middle
    }
    
    @ViewBuilder var quickViewOverlay: some View {
        VStack {
            Spacer()
            MapQuickView(
                page: activePinIndex,
                mapViewModel: mapViewModel
            ) { index in
                withAnimation {
                    updateSelectedPin(index: index)
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder var mapBody: some View {
        MapKitViewV2(
            region: regionWrapper.region,
            selectedPin: $selectedPin,
            annotations: mapViewModel.mapPins.pins.map { PlaceAnnotation(pin: $0, zIndex: $0.posts.count) }
        ) { coordinate in
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                if let placemark = placemarks?.first {
                    let mapItem = MKMapItem(placemark: MKPlacemark(placemark: placemark))
                    createPostVM.selectPlace(placeSelection: mapItem)
                    showCreatePost.toggle()
                }
            }
        }
        .edgesIgnoringSafeArea(.top)
        .overlay(mapOverlay)
        .overlay(quickViewDisplayed ? quickViewOverlay : nil)
        .sheet(isPresented: $showCreatePost, onDismiss: { createPostVM.resetPlace() }) {
            CreatePostWithModel(createPostVM: createPostVM, presented: $showCreatePost)
                .environmentObject(appState)
                .environmentObject(globalViewState)
        }
        .bottomSheet(
            bottomSheetPosition: $bottomSheetPosition,
            options: [
                .animation(Animation.interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0)),
                .background(AnyView(Color("background")))
            ],
            headerContent: {
                MapBottomSheetHeader(
                    mapViewModel: mapViewModel,
                    searchFieldActive: $searchFieldActive,
                    bottomSheetPosition: $bottomSheetPosition,
                    showHelpAlert: $showHelpAlert
                )
            }, mainContent: {
                switch mapViewModel.loadStatus {
                case .loading:
                    ProgressView()
                case .failed:
                    Button(action: { mapViewModel.refreshMap(appState: appState, globalViewState: globalViewState )}) {
                        Text("Failed to load map. Tap to try again.").font(.caption).foregroundColor(.blue)
                    }
                case .success:
                    MapBottomSheet(mapViewModel: mapViewModel, bottomSheetPosition: $bottomSheetPosition)
                        .ignoresSafeArea(.keyboard, edges: .all)
                }
            }
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    /// This is a separate view because the map lags when initially showing the popup in a regular ZStack
    var popupBody: some View {
        ZStack {
        }
        .popup(
            isPresented: $showHelpAlert,
            type: .default,
            position: .top,
            animation: .interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0),
            autohideIn: nil,
            dragToDismiss: false,
            closeOnTap: false,
            closeOnTapOutside: false,
            backgroundColor: .black.opacity(0.3),
            dismissCallback: {}) {
                MapInfoView(presented: $showHelpAlert)
            }
    }
    
    var body: some View {
        mapBody
            .overlay(popupBody)
            .appear {
                if !initialized {
                    initialized = true
                    if shouldShowHelpInfo {
                        showHelpAlert = true
                        shouldShowHelpInfo = false
                    }
                    mapViewModel.locationManager.requestWhenInUseAuthorization()
                    mapViewModel.locationManager.startUpdatingLocation()
                    mapViewModel.listenToSearchQuery(appState: appState, globalViewState: globalViewState)
                    mapViewModel.refreshMap(appState: appState, globalViewState: globalViewState)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        if preselectedPost == nil, let location = mapViewModel.locationManager.location {
                            regionWrapper.region.wrappedValue = MKCoordinateRegion(
                                center: location.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
                            )
                            regionWrapper.trigger.toggle()
                        }
                    }
                }
            }
            .onChange(of: bottomSheetPosition) { newPos in
                if newPos == .hidden {
                    hideKeyboard()
                }
            }
            .onChange(of: selectedPin) { selectedPin in
                withAnimation {
                    if let selectedPin = selectedPin {
                        updatePage(pin: selectedPin)
                        moveToPin(pin: selectedPin)
                    } else {
                        deselectPin()
                    }
                }
            }
            .onChange(of: mapViewModel.loadStatus) { status in
                if preselectedPost == nil && status != .loading {
                    withAnimation {
                        bottomSheetPosition = .middle
                    }
                }
            }
            .onChange(of: mapViewModel.mapPins) { mapPins in
                if let post = preselectedPost, !finishedPreselectingPost {
                    if let pin = mapPins.pins.first(where: { $0.place.id == post.place.id }) {
                        finishedPreselectingPost = true
                        selectedPin = pin
                    } else {
                        mapViewModel.preselectPost(post: post)
                    }
                }
            }
    }
}

fileprivate struct BulletedText: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle")
                .resizable()
                .scaledToFit()
                .frame(width: 4, height: 18)
            
            Text(text)
        }
    }
}

fileprivate struct MapInfoView: View {
    @Binding var presented: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 5) {
                Spacer()
                Text("Welcome to the")
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44)
                Text("Map")
                Spacer()
            }
            .font(.system(size: 16, weight: .bold))
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Below are some key tips").frame(maxWidth: .infinity, alignment: .center)
                
                BulletedText("To optimize map performance, not all pins are loaded. Long press on someone's profile to load more pins.")
                BulletedText("Tap on the categories at the top of the screen to filter by your preference.")
                BulletedText("Use the search bar to add more people's pins to the map.")
                BulletedText("It may take a couple minutes for new posts to appear on the map.")
            }
            
            HStack {
                Spacer()
                Text("Love you, the jimo team")
            }
            
            Button(action: { presented.toggle() }) {
                Text("Love you too")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .contentShape(Rectangle())
            }
        }
        .multilineTextAlignment(.leading)
        .font(.system(size: 14))
        .padding(20)
        .frame(width: 320)
        .background(BlurBackground(effect: UIBlurEffect(style: .systemThickMaterial)))
        .cornerRadius(10.0)
    }
}

fileprivate struct CurrentLocationButton: View {
    var regionWrapper: RegionWrapper
    
    var locationManager: CLLocationManager
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation {
                if let location = locationManager.location {
                    regionWrapper.region.wrappedValue = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                    regionWrapper.trigger.toggle()
                } else {
                    print("Could not get location")
                }
            }
        }) {
            ZStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 20))
                    .frame(width: 50, height: 50)
                    .background(Color("background"))
                    .cornerRadius(25)
                    .contentShape(Circle())
            }
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(radius: 3)
    }
}
