//
//  MapTab.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/18/21.
//

import SwiftUI

struct MapTab: View {
    var body: some View {
        NavigationView {
            MapViewV2()
                .navigationBarHidden(true)
                .trackScreen(.mapTab)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
