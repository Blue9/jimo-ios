//
//  MapTab.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/18/21.
//

import SwiftUI

struct MapTab: View {
    let mapModel: MapModel
    let localSettings: LocalSettings
    let mapViewModel: MapViewModel
    
    var body: some View {
        NavigationView {
            MapView(mapModel: mapModel, localSettings: localSettings, mapViewModel: mapViewModel)
                .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MapTab_Previews: PreviewProvider {
    static let appState = AppState(apiClient: APIClient())
    static let viewState = GlobalViewState()
    
    static var previews: some View {
        MapTab(
            mapModel: appState.mapModel,
            localSettings: appState.localSettings,
            mapViewModel: MapViewModel(appState: appState, viewState: viewState)
        )
    }
}
