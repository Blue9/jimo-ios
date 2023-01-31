//
//  MapTab.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/18/21.
//

import SwiftUI

struct MapTab: View {
    @EnvironmentObject var deepLinkManager: DeepLinkManager

    var body: some View {
        Navigator {
            MapViewV2()
                .navigation(item: $deepLinkManager.presentableEntity, destination: deepLinkManager.viewForDeepLink)
                .navigationBarHidden(true)
                .trackScreen(.mapTab)
        }
    }
}
