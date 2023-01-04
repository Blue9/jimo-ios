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
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @StateObject var mapViewModel = MapViewModel()
    @StateObject var locationSearch = LocationSearch()
    @StateObject var sheetViewModel = SheetPositionViewModel()
    
    @State private var initialized = false
    
    var body: some View {
        BaseMapViewV2(mapViewModel: mapViewModel, locationSearch: locationSearch, sheetViewModel: sheetViewModel)
            .appear {
                if !initialized {
                    initialized = true
                    mapViewModel.initializeMap(appState: appState, viewState: globalViewState)
                }
            }
    }
}

struct BaseMapViewV2: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var globalViewState: GlobalViewState
    
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var locationSearch: LocationSearch
    @ObservedObject var sheetViewModel: SheetPositionViewModel
    
    @FocusState private var searchFieldActive: Bool
    
    @ViewBuilder var mapOverlay: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                CurrentLocationButton(region: mapViewModel.region)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }
    
    @ViewBuilder var mapBody: some View {
        JimoMapView(
            pins: $mapViewModel.pins,
            selectedPin: $mapViewModel.selectedPin,
            regionWrapper: mapViewModel,
            selectPin: { pin in
                sheetViewModel.businessSheetPosition = .relative(0.6)
                mapViewModel.selectPin(
                    appState: appState,
                    viewState: globalViewState,
                    pin: pin
                )
            }
        )
        .edgesIgnoringSafeArea(.top)
        .overlay(mapOverlay)
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
                    searchFieldActive: $searchFieldActive
                )
            }, mainContent: {
                MapBottomSheetBody(
                    mapViewModel: mapViewModel,
                    locationSearch: locationSearch,
                    businessSheetPosition: $sheetViewModel.businessSheetPosition
                )
                .onChange(of: searchFieldActive) { active in
                    if active {
                        sheetViewModel.bottomSheetPosition = .relative(MapSheetPosition.top.rawValue)
                    } else {
                        sheetViewModel.bottomSheetPosition = .relative(MapSheetPosition.middle.rawValue)
                    }
                }
                .ignoresSafeArea(.keyboard, edges: .all)
            }
        )
        .enableFlickThrough()
        .customBackground(AnyView(Color("background")).cornerRadius(10))
        .customAnimation(.spring(response: 0.24, dampingFraction: 0.75, blendDuration: 0.1))
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    var body: some View {
        mapBody
            .bottomSheet(
                bottomSheetPosition: $sheetViewModel.businessSheetPosition,
                switchablePositions: [
                    .absoluteBottom(120),
                    .relative(0.6),
                    .relative(MapSheetPosition.top.rawValue)
                ],
                headerContent: {
                    VStack(alignment: .leading) {
                        Text(mapViewModel.displayedPlaceDetails?.name ?? "")
                            .font(.title2)
                            .bold()
                        Text(mapViewModel.displayedPlaceDetails?.address ?? "")
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                }, mainContent: {
                    if let result = mapViewModel.displayedPlaceDetails {
                        MapSearchResultBody(result: result)
                            .padding(.top, 10)
                    }
                }
            )
            .customAnimation(.spring(response: 0.24, dampingFraction: 0.75, blendDuration: 0.1))
            .customBackground(AnyView(Color("background")).cornerRadius(10))
            .showCloseButton()
            .onDismiss {
                mapViewModel.selectedPin = nil
                sheetViewModel.bottomSheetPosition = .relative(MapSheetPosition.middle.rawValue)
            }
    }
}
