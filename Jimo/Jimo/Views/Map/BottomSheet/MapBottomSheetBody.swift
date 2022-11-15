//
//  MapBottomSheet.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/22/22.
//

import SwiftUI
import BottomSheet

enum MapSheetPosition: CGFloat, CaseIterable {
    case top = 0.975, middle = 0.4, bottom = 0.2
}

struct MapBottomSheetBody: View {
    @ObservedObject var mapViewModel: MapViewModelV2
    @Binding var bottomSheetPosition: BottomSheetPosition
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                UserFilter(mapViewModel: mapViewModel).padding(.trailing)
            }
            .padding(.top, 10)
        }
        .padding(.leading)
    }
}
