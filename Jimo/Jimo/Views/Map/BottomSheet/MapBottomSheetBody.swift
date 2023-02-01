//
//  MapBottomSheet.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/22/22.
//

import SwiftUI
import BottomSheet
import MapKit

enum MapSheetPosition: CGFloat, CaseIterable {
    case top = 0.975, middle = 0.4, bottom = 0.15
}

struct MapBottomSheetBody: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState

    @ObservedObject var placeViewModel: PlaceDetailsViewModel
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var locationSearch: LocationSearch
    @ObservedObject var sheetViewModel: SheetPositionViewModel
    @FocusState.Binding var searchFieldActive: Bool

    var searching: Bool {
        locationSearch.searchQuery.count > 0
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    if appState.me == nil {
                        UnauthedMapUserFilter(
                            customUserFilter: $mapViewModel.userIds,
                            mapType: $mapViewModel.mapType
                        )
                    } else {
                        AuthedMapUserFilter(
                            mapType: $mapViewModel.mapType,
                            customUserFilter: $mapViewModel.userIds
                        )
                    }
                    CategoryFilter(selected: $mapViewModel.categories)
                        .opacity(mapViewModel.mapType != .saved ? 1 : 0)
                    Spacer()
                }
            }
            .padding(.horizontal, 10)
            .opacity(searching ? 0 : 1)

            if searching {
                MapSearchResults(locationSearch: locationSearch) { selectedPlace in
                    DispatchQueue.main.async {
                        Analytics.track(.mapSearchResultTapped)
                        withAnimation {
                            searchFieldActive = false
                            sheetViewModel.businessSheetPosition = .relative(0.6)
                            sheetViewModel.bottomSheetPosition = .hidden
                            // sheetViewModel.businessSheetPosition = .relative(0.6)
                            mapViewModel.selectSearchResult(
                                placeViewModel: placeViewModel,
                                appState: appState,
                                viewState: viewState,
                                mapItem: selectedPlace
                            )
                        }
                    }
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 49)
    }
}

private struct AuthedMapUserFilter: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState

    @StateObject var userFilterViewModel = AuthedUserFilterViewModel()

    @Binding var mapType: MapType
    @Binding var customUserFilter: Set<UserId>

    @State private var showMoreUsersSheet = false

    var body: some View {
        VStack {
            HStack {
                Text("Filter pins")
                    .font(.system(size: 15))
                    .bold()
                Spacer()
            }
            .padding(.top, 5)
            .padding(.leading, 5)

            HStack(spacing: 0) {
                MapUserFilterButton(mapType: .saved, selectedMapType: $mapType)
                MapUserFilterButton(mapType: .me, selectedMapType: $mapType)
                MapUserFilterButton(mapType: .following, selectedMapType: $mapType)
                MapUserFilterButton(mapType: .community, selectedMapType: $mapType)
                MapUserFilterButton(mapType: .custom, selectedMapType: $mapType, onTap: {
                    showMoreUsersSheet = true
                })
            }
        }
        .padding(5)
        .background(Color("foreground").opacity(0.1))
        .cornerRadius(10)
        .sheet(isPresented: $showMoreUsersSheet, onDismiss: {
            if userFilterViewModel.selectedUsers.isEmpty {
                DispatchQueue.main.async {
                    mapType = .following
                }
            }
        }) {
            CustomUserFilter(
                viewModel: userFilterViewModel,
                onSubmit: { userIds in customUserFilter = userIds }
            )
            .environmentObject(appState)
            .environmentObject(viewState)
        }
    }
}

private struct MapUserFilterButton: View {
    @EnvironmentObject var appState: AppState

    var mapType: MapType
    @Binding var selectedMapType: MapType

    var onTap: (() -> Void)?

    var selected: Bool {
        selectedMapType == mapType
    }

    var profilePicture: some View {
        URLImage(
            url: appState.me?.profilePictureUrl,
            loading: Image(systemName: "person.crop.circle.fill").renderingMode(.original).resizable()
        ).font(.system(size: 14, weight: .thin))
    }

    var body: some View {
        VStack {
            if let systemName = mapType.systemImage {
                Image(systemName: systemName)
                    .resizable()
                    .font(.system(size: 14, weight: .thin))
                    .foregroundStyle(Color("foreground").opacity(0.8), Color("foreground").opacity(0.1))
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if mapType == .community {
                GlobalViewFilterButton()
            } else if mapType == .me {
                profilePicture
                    .foregroundColor(Color("background").opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(100)
            }
            Text(mapType.buttonName)
                .lineLimit(1)
                .font(.caption)
        }
        .padding(5)
        .background(selected ? Color("foreground").opacity(0.1) : nil)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedMapType = mapType
            onTap?()
        }
        .cornerRadius(10)
    }
}
