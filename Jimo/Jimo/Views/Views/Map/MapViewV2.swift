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

struct MapViewV2: View {
    @AppStorage("shouldShowHelpInfo") var shouldShowHelpInfo = true
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    let geocoder = CLGeocoder()
    
    @StateObject var mapViewModel = MapViewModelV2()
    @StateObject var createPostVM = CreatePostVM()
    @StateObject var regionWrapper = RegionWrapper()
    @StateObject var quickViewModel = QuickViewModel()
    
    @State private var showCreatePost = false
    @State private var bottomSheetPosition: MapSheetPosition = .bottom
    @State private var searchFieldActive = false
    
    @State private var initialized = false
    @State private var firstLoad = true
    
    @State private var showHelpAlert = false
    
    var quickViewDisplayed: Bool {
        mapViewModel.selectedPin != nil
    }
    
    @ViewBuilder var mapOverlay: some View {
        VStack(spacing: 0) {
            if !quickViewDisplayed {
                CategoryFilter(selectedCategories: $mapViewModel.selectedCategories)
            }
            HStack {
                Spacer()
                CurrentLocationButton(regionWrapper: regionWrapper)
                    .padding(.horizontal)
            }
            Spacer()
        }
        .animation(.easeInOut, value: quickViewDisplayed)
    }
    
    private func selectPin(pin: MapPinV3) {
        bottomSheetPosition = .hidden
        regionWrapper.region.center.wrappedValue = pin.location.coordinate()
        if regionWrapper.region.span.longitudeDelta.wrappedValue > 0.2 {
            regionWrapper.region.span.wrappedValue = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        }
        regionWrapper.trigger.toggle()
    }
    
    @ViewBuilder var quickViewOverlay: some View {
        VStack(spacing: 5) {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    mapViewModel.selectedPin = nil
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                        .frame(width: 40, height: 40)
                        .background(Color("background"))
                        .cornerRadius(10)
                        .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, (UIScreen.main.bounds.width - 320) / 2)
            
            MapQuickView(
                mapViewModel: mapViewModel,
                quickViewModel: quickViewModel
            ) { index in
                withAnimation {
                    mapViewModel.selectPin(index: index)
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder var mapBody: some View {
        MapKitViewV2(
            region: regionWrapper.region,
            selectedPin: $mapViewModel.selectedPin,
            annotations: mapViewModel.pins.map { PlaceAnnotationV2(pin: $0, zIndex: $0.icon.numPosts) }
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
                MapBottomSheet(mapViewModel: mapViewModel, bottomSheetPosition: $bottomSheetPosition)
                    .ignoresSafeArea(.keyboard, edges: .all)
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
                    mapViewModel.initialize(
                        appState: appState,
                        viewState: globalViewState,
                        regionWrapper: regionWrapper
                    )
                }
            }
            .onChange(of: mapViewModel.selectedPin) { selectedPin in
                withAnimation {
                    if let selectedPin = selectedPin {
                        selectPin(pin: selectedPin)
                    } else {
                        bottomSheetPosition = .middle
                    }
                }
            }
            .onChange(of: mapViewModel.mapLoadStatus) { status in
                if status != .loading && firstLoad {
                    firstLoad = false
                    withAnimation {
                        bottomSheetPosition = .middle
                    }
                }
            }
    }
}
