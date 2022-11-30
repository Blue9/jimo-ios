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
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    let geocoder = CLGeocoder()
    
    @StateObject var mapViewModel = MapViewModelV2()
    @StateObject var createPostVM = CreatePostVM()
    @StateObject var regionWrapper = RegionWrapper()
    @StateObject var quickViewModel = QuickViewModel()
    
    @State private var showCreatePost = false
    @State private var bottomSheetPosition: BottomSheetPosition = .relative(MapSheetPosition.bottom.rawValue)
    @State private var searchFieldActive = false
    
    @State private var initialized = false
    @State private var firstLoad = true

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
            region: regionWrapper.region,
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
            bottomSheetPosition: $bottomSheetPosition,
            switchablePositions: [
                .relative(MapSheetPosition.bottom.rawValue),
                .relative(MapSheetPosition.middle.rawValue),
                .relative(MapSheetPosition.top.rawValue)
            ],
            headerContent: {
                MapBottomSheetHeader(
                    mapViewModel: mapViewModel,
                    searchFieldActive: $searchFieldActive,
                    bottomSheetPosition: $bottomSheetPosition
                )
            }, mainContent: {
                MapBottomSheetBody(mapViewModel: mapViewModel, bottomSheetPosition: $bottomSheetPosition)
                    .ignoresSafeArea(.keyboard, edges: .all)
            }
        )
        .customBackground(AnyView(Color("background")))
        .customAnimation(.interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0))
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    var body: some View {
        mapBody
            .appear {
                if !initialized {
                    initialized = true
                    mapViewModel.initialize(
                        appState: appState,
                        viewState: globalViewState,
                        regionWrapper: regionWrapper
                    )
                }
            }
            .onChange(of: mapViewModel.selectedPin) { selectedPin in
                withAnimation {
                    if selectedPin != nil {
                        bottomSheetPosition = .hidden
                    } else {
                        bottomSheetPosition = .relative(MapSheetPosition.middle.rawValue)
                    }
                }
            }
            .onChange(of: mapViewModel.mapLoadStatus) { status in
                if status != .loading && firstLoad {
                    firstLoad = false
                    withAnimation {
                        bottomSheetPosition = .relative(MapSheetPosition.middle.rawValue)
                    }
                }
            }
    }
}
