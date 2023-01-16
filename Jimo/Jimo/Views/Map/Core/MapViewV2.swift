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
    @Published var bottomSheetPosition: BottomSheetPosition = .relative(MapSheetPosition.bottom.rawValue)
    @Published var businessSheetPosition: BottomSheetPosition = .hidden
    
    func showBusinessSheet() {
        DispatchQueue.main.async {
            self.businessSheetPosition = .relative(0.6)
            self.bottomSheetPosition = .hidden
        }
    }
    
    func showSearchSheet(_ position: MapSheetPosition? = nil) {
        DispatchQueue.main.async {
            self.bottomSheetPosition = .relative(position?.rawValue ?? MapSheetPosition.middle.rawValue)
            self.businessSheetPosition = .hidden
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
                DispatchQueue.main.async {
                    if !initialized {
                        initialized = true
                        mapViewModel.initializeMap(appState: appState, viewState: globalViewState, onLoad: { numPins in
                            if numPins < 5 {
                                sheetViewModel.showSearchSheet()
                            }
                        })
                    }
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
    
    @StateObject private var userFilterViewModel = UserFilterViewModel()
    
    @FocusState private var searchFieldActive: Bool
    
    @ViewBuilder var mapOverlay: some View {
        VStack(spacing: 0) {
            HStack {
                if mapViewModel.isLoading {
                    ProgressView()
                }
                Spacer()
                CurrentLocationButton(setRegion: mapViewModel.setRegion)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }
    
    @ViewBuilder var mapBody: some View {
        JimoMapView(
            mapViewModel: mapViewModel,
            tappedPin: { pin in
                if let pin = pin {
                    Analytics.track(.mapPinTapped)
                    mapViewModel.selectPin(
                        appState: appState,
                        viewState: globalViewState,
                        pin: pin
                    )
                    print("Setting businessSheetPosition to mid")
                    sheetViewModel.showBusinessSheet()
                } else {
                    mapViewModel.displayedPlaceDetails?.isStale = true
                    mapViewModel.selectedPin = nil
                    print("Setting filterSheetPosition to mid")
                    sheetViewModel.showSearchSheet()
                }
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
                    userFilterViewModel: userFilterViewModel,
                    locationSearch: locationSearch,
                    sheetViewModel: sheetViewModel,
                    searchFieldActive: $searchFieldActive
                )
                .onChange(of: searchFieldActive) { active in
                    DispatchQueue.main.async {
                        if active {
                            sheetViewModel.showSearchSheet(.top)
                        } else {
                            sheetViewModel.showSearchSheet(.middle)
                        }
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
                    .opacity(mapViewModel.displayedPlaceDetails?.isStale ?? false ? 0.5 : 1.0)
                    .renderAsPlaceholder(if: mapViewModel.displayedPlaceDetails?.isStale ?? true)
                }, mainContent: {
                    if let result = mapViewModel.displayedPlaceDetails {
                        PlaceDetailsView(result: result)
                            .renderAsPlaceholder(if: mapViewModel.displayedPlaceDetails?.isStale ?? true)
                            .padding(.top, 10)
                    }
                }
            )
            .customAnimation(.spring(response: 0.24, dampingFraction: 0.75, blendDuration: 0.1))
            .customBackground(AnyView(Color("background")).cornerRadius(10))
            .showCloseButton()
            .onDismiss {
                DispatchQueue.main.async {
                    mapViewModel.displayedPlaceDetails?.isStale = true
                    mapViewModel.selectedPin = nil
                    sheetViewModel.showSearchSheet()
                }
            }
    }
}

fileprivate extension View {
    @ViewBuilder
    func renderAsPlaceholder(if condition: Bool) -> some View {
        if condition {
            self.redacted(reason: .placeholder)
        } else {
            self
        }
    }
}
