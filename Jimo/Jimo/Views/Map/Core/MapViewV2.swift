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

class SheetPositionViewModel: ObservableObject {
    @Published var bottomSheetPosition: BottomSheetPosition = .relative(MapSheetPosition.bottom.rawValue) {
        didSet {
            if bottomSheetPosition != .hidden {
                businessSheetPosition = .hidden
            }
        }
    }
    @Published var businessSheetPosition: BottomSheetPosition = .hidden {
        didSet {
            if businessSheetPosition != .hidden {
                bottomSheetPosition = .hidden
            }
        }
    }
}

struct MapViewV2: View {
    @AppStorage("shouldShowHelpInfo") var shouldShowHelpInfo = true
    
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    let geocoder = CLGeocoder()
    
    @StateObject var mapViewModel = MapViewModelV2()
    @StateObject var createPostVM = CreatePostVM()
    @StateObject var regionWrapper = RegionWrapper()
    @StateObject var quickViewModel = QuickViewModel()
    @StateObject var locationSearch = LocationSearch()
    @StateObject var sheetViewModel = SheetPositionViewModel()
    
    @State private var showMKMapItem: MKMapItem?
    @State private var showCreatePost = false
    
    @FocusState private var searchFieldActive: Bool
    
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
            )
        }
        .padding()
    }
    
    @ViewBuilder var mapBody: some View {
        JimoMapView(
            pins: $mapViewModel.pins,
            selectedPin: $mapViewModel.selectedPin,
            regionWrapper: regionWrapper,
            mapViewModel: mapViewModel
        )
        .edgesIgnoringSafeArea(.top)
        .overlay(mapOverlay)
        .overlay(quickViewDisplayed ? quickViewOverlay : nil)
        .sheet(isPresented: $showCreatePost, onDismiss: { createPostVM.resetPlace() }) {
            CreatePostWithModel(createPostVM: createPostVM, presented: $showCreatePost)
                .environmentObject(appState)
                .environmentObject(globalViewState)
        }
        .bottomSheet(
            bottomSheetPosition: $sheetViewModel.bottomSheetPosition,
            switchablePositions: [
                .relative(MapSheetPosition.bottom.rawValue),
                .relative(MapSheetPosition.middle.rawValue),
                .relative(MapSheetPosition.top.rawValue)
            ],
            headerContent: {
                MapBottomSheetHeader(
                    locationSearch: locationSearch,
                    bottomSheetPosition: $sheetViewModel.bottomSheetPosition,
                    showHelpAlert: $showHelpAlert,
                    searchFieldActive: $searchFieldActive
                )
            }, mainContent: {
                MapBottomSheetBody(
                    mapViewModel: mapViewModel,
                    locationSearch: locationSearch,
                    sheetViewModel: sheetViewModel,
                    showMKMapItem: $showMKMapItem
                ).ignoresSafeArea(.keyboard, edges: .all)
            }
        )
        .enableFlickThrough()
        .customBackground(AnyView(Color("background")).cornerRadius(10))
        .customAnimation(.spring(response: 0.24, dampingFraction: 0.75, blendDuration: 0.1))
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
            .bottomSheet(
                bottomSheetPosition: $sheetViewModel.businessSheetPosition,
                switchablePositions: [
                    .relative(MapSheetPosition.middle.rawValue),
                    .relative(0.6),
                    .relative(MapSheetPosition.top.rawValue)
                ],
                headerContent: {
                    VStack {
                        HStack {
                            Text("Helloooooooooooo")
                            Spacer()
                        }
                    }
                }, mainContent: {
                    if let place = showMKMapItem {
                        ScrollView {
                            VStack {
                                Text(place.placemark.name ?? "View place details")
                                Text(place.debugDescription)
                                Spacer()
                            }
                        }
                    }
                }
            )
            .customAnimation(.spring(response: 0.24, dampingFraction: 0.75, blendDuration: 0.1))
            .customBackground(AnyView(Color("background")).cornerRadius(10))
            .showCloseButton()
            .enableTapToDismiss()
            .onDismiss {
                sheetViewModel.bottomSheetPosition = .relative(MapSheetPosition.middle.rawValue)
            }
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
            .onChange(of: searchFieldActive) { isActive in
                withAnimation {
                    if isActive {
                        sheetViewModel.bottomSheetPosition = .relative(MapSheetPosition.top.rawValue)
                    }
                }
            }
            .onChange(of: mapViewModel.selectedPin) { selectedPin in
                withAnimation {
                    if selectedPin != nil {
                        sheetViewModel.bottomSheetPosition = .hidden
                    } else {
                        sheetViewModel.bottomSheetPosition = .relative(MapSheetPosition.middle.rawValue)
                    }
                }
            }
            .onChange(of: mapViewModel.mapLoadStatus) { status in
                if status != .loading && firstLoad {
                    firstLoad = false
                    sheetViewModel.bottomSheetPosition = .relative(MapSheetPosition.middle.rawValue)
                }
            }
    }
}
