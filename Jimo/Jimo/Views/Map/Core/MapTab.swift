//
//  MapTab.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/18/21.
//

import SwiftUI

struct MapTab: View {
    @StateObject private var navigationState = NavigationState()

    var body: some View {
        Navigator(state: navigationState) {
            MapViewV2()
                .navigationBarHidden(true)
                .trackScreen(.mapTab)
        }
    }
}
