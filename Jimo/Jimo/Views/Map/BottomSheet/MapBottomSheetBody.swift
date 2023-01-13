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
    
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var userFilterViewModel: UserFilterViewModel
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
                    MapUserFilter(
                        userFilterViewModel: userFilterViewModel,
                        mapType: $mapViewModel.mapType,
                        customUserFilter: $mapViewModel.userIds
                    )
                    CategoryFilter(selected: $mapViewModel.categories)
                    Spacer()
                }
            }
            .padding(.horizontal, 10)
            .opacity(searching ? 0 : 1)
            
            if searching {
                MapSearchResults(locationSearch: locationSearch) { selectedPlace in
                    DispatchQueue.main.async {
                        withAnimation {
                            searchFieldActive = false
                            sheetViewModel.businessSheetPosition = .relative(0.6)
                            sheetViewModel.bottomSheetPosition = .hidden
                            //sheetViewModel.businessSheetPosition = .relative(0.6)
                            mapViewModel.selectSearchResult(
                                appState: appState,
                                viewState: viewState,
                                mapItem: selectedPlace
                            )
                            print("searchFieldActive \(searchFieldActive) :: \(sheetViewModel.bottomSheetPosition) \(sheetViewModel.businessSheetPosition)")
                        }
                    }
                }
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 49)
    }
}

fileprivate struct MapUserFilter: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    
    @ObservedObject var userFilterViewModel: UserFilterViewModel
    
    @Binding var mapType: MapType
    @Binding var customUserFilter: Set<UserId>
    
    @State private var showMoreUsersSheet = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Filter by people")
                    .font(.system(size: 15))
                    .bold()
                Spacer()
            }
            .padding(.top, 5)
            .padding(.leading, 5)
            
            HStack(spacing: 0) {
                MapUserFilterButton(mapType: .me, selectedMapType: $mapType)
                MapUserFilterButton(mapType: .following, selectedMapType: $mapType)
                MapUserFilterButton(mapType: .saved, selectedMapType: $mapType)
                MapUserFilterButton(mapType: .community, selectedMapType: $mapType)
                MapUserFilterButton(mapType: .custom, selectedMapType: $mapType, onTap: {
                    showMoreUsersSheet = true
                })
            }
        }
        .padding(5)
        .background(Color("foreground").opacity(0.1))
        .cornerRadius(10)
        .sheet(isPresented: $showMoreUsersSheet) {
            CustomUserFilter(
                viewModel: userFilterViewModel,
                onSubmit: { userIds in customUserFilter = userIds }
            )
            .environmentObject(appState)
            .environmentObject(viewState)
        }
    }
}

fileprivate struct MapUserFilterButton: View {
    @EnvironmentObject var appState: AppState
    
    var mapType: MapType
    @Binding var selectedMapType: MapType
    
    var onTap: (() -> ())?
    
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
                GlobalViewButton()
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

fileprivate struct GlobalViewButton: View {
    var body: some View {
        ZStack {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(5)
            Circle()
                .stroke(Colors.angularGradient, style: StrokeStyle(lineWidth: 2.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

fileprivate extension MapType {
    var buttonName: String {
        switch self {
        case .me: return "Me"
        case .following: return "Friends"
        case .saved: return "Saved"
        case .community: return "Everyone"
        case .custom: return "More"
        }
    }
    
    var systemImage: String? {
        switch self {
        case .following: return "person.2.circle.fill"
        case .saved: return "bookmark.circle.fill"
        case .custom: return "ellipsis.circle.fill"
        default: return nil
        }
    }
}
