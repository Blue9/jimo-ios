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
    case top = 0.975, middle = 0.375, bottom = 0.15
}

struct MapBottomSheetBody: View {
    @ObservedObject var mapViewModel: MapViewModelV2
    @ObservedObject var locationSearch: LocationSearch
    @ObservedObject var sheetViewModel: SheetPositionViewModel
    @Binding var showMKMapItem: MKMapItem?
    
    var searching: Bool {
        locationSearch.searchQuery.count > 0
    }
    
    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack {
                    MapUserFilter(mapLoadStrategy: $mapViewModel.mapLoadStrategy, customUserFilter: $mapViewModel.customUserFilter)
                    Spacer()
                }
            }
            .padding(.horizontal, 10)
            .opacity(searching ? 0 : 1)
            
            if searching {
                MapSearchResults(locationSearch: locationSearch) { selectedPlace in
                    withAnimation {
                        hideKeyboard()
                        sheetViewModel.businessSheetPosition = .relative(MapSheetPosition.middle.rawValue)
                        mapViewModel.regionWrapper.region.wrappedValue.center = selectedPlace.placemark.coordinate
                        mapViewModel.regionWrapper.trigger.toggle()
                        showMKMapItem = selectedPlace
                    }
                }
            }
        }
//        .animation(.default, value: searching)
        .padding(.top, 10)
        .padding(.bottom, 49)
    }
}

fileprivate struct MapUserFilter: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    
    @Binding var mapLoadStrategy: MapLoadStrategy
    @Binding var customUserFilter: Set<UserId>
    
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
                MapUserFilterButton(mapLoadStrategy: .me, selectedMapLoadStrategy: $mapLoadStrategy)
                MapUserFilterButton(mapLoadStrategy: .friends, selectedMapLoadStrategy: $mapLoadStrategy)
                MapUserFilterButton(mapLoadStrategy: .savedPosts, selectedMapLoadStrategy: $mapLoadStrategy)
                MapUserFilterButton(mapLoadStrategy: .everyone, selectedMapLoadStrategy: $mapLoadStrategy)
                MapUserFilterButton(mapLoadStrategy: .custom, selectedMapLoadStrategy: $mapLoadStrategy)
            }
        }
        .padding(5)
        .background(Color("foreground").opacity(0.1))
        .cornerRadius(10)
    }
}

fileprivate struct MapUserFilterButton: View {
    @EnvironmentObject var appState: AppState
    
    var mapLoadStrategy: MapLoadStrategy
    @Binding var selectedMapLoadStrategy: MapLoadStrategy
    
    var selected: Bool {
        selectedMapLoadStrategy == mapLoadStrategy
    }
    
    var profilePicture: some View {
        URLImage(
            url: appState.me?.profilePictureUrl,
            loading: Image(systemName: "person.crop.circle.fill").renderingMode(.original).resizable()
        ).font(.system(size: 14, weight: .thin))
    }
    
    var body: some View {
        VStack {
            if let systemName = mapLoadStrategy.systemImage {
                Image(systemName: systemName)
                    .resizable()
                    .font(.system(size: 14, weight: .thin))
                    .foregroundStyle(Color("foreground").opacity(0.8), Color("foreground").opacity(0.1))
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if mapLoadStrategy == .everyone {
                GlobalViewButton()
            } else if mapLoadStrategy == .me {
                profilePicture
                    .foregroundColor(Color("background").opacity(0.5))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(100)
            }
            Text(mapLoadStrategy.buttonName)
                .lineLimit(1)
                .font(.caption)
        }
        .padding(5)
        .background(selected ? Color("foreground").opacity(0.1) : nil)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedMapLoadStrategy = mapLoadStrategy
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

fileprivate extension MapLoadStrategy {
    var buttonName: String {
        switch self {
        case .me: return "Me"
        case .friends: return "Friends"
        case .savedPosts: return "Saved"
        case .everyone: return "Everyone"
        case .custom: return "More"
        case .none: return ""
        }
    }
    
    var systemImage: String? {
        switch self {
        case .friends: return "person.2.circle.fill"
        case .savedPosts: return "bookmark.circle.fill"
        case .custom: return "ellipsis.circle.fill"
        default: return nil
        }
    }
}
