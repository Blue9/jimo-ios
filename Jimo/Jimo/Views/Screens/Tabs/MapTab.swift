//
//  MapTab.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/18/21.
//

import SwiftUI

struct MapTab: View {
    let mapModel: MapModel
    let mapViewModel: MapViewModel
    
    var body: some View {
        NavigationView {
            MapView(mapModel: mapModel, mapViewModel: mapViewModel)
                .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct MapTab_Previews: PreviewProvider {
    static let appState = AppState(apiClient: APIClient())
    
    static var previews: some View {
        MapTab(mapModel: appState.mapModel, mapViewModel: MapViewModel(appState: appState))
    }
}
