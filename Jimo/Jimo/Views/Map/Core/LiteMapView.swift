//
//  LiteMapView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/25/22.
//

import SwiftUI
import MapKit


struct LiteMapView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var viewState: GlobalViewState
    
    @StateObject var mapViewModel = MapViewModel()
    @StateObject var locationSearch = LocationSearch()
    @StateObject var sheetViewModel = SheetPositionViewModel()
    
    var post: Post
    
    var pin: MKJimoPinAnnotation {
        MKJimoPinAnnotation(from: MapPin(
            placeId: post.place.id,
            location: post.place.location,
            icon: MapPinIcon(category: post.category, iconUrl: post.user.profilePictureUrl, numPosts: 1)
        ))
    }
    
    var body: some View {
        BaseMapViewV2(mapViewModel: mapViewModel, locationSearch: locationSearch, sheetViewModel: sheetViewModel)
            .onAppear {
                DispatchQueue.main.async {
                    mapViewModel.pins = [pin]
                    mapViewModel.selectPin(appState: appState, viewState: viewState, pin: pin)
                    sheetViewModel.showBusinessSheet()
                    mapViewModel.listenToRegionChanges(appState: appState, viewState: viewState)
                }
            }
    }
}
