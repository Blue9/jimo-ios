//
//  MapBottomSheetHeader.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/22/22.
//

import SwiftUI
import BottomSheet

struct MapBottomSheetHeader: View {
    @ObservedObject var mapViewModel: MapViewModelV2
    
    @Binding var searchFieldActive: Bool
    @Binding var bottomSheetPosition: BottomSheetPosition
    
    @Binding var showHelpAlert: Bool
    
    var body: some View {
        HStack {
            MapSearchField(text: $mapViewModel.searchUsersQuery, isActive: $searchFieldActive, placeholder: "Filter by people", onCommit: {})
                .ignoresSafeArea(.keyboard, edges: .all)
                .onChange(of: searchFieldActive) { isActive in
                    withAnimation {
                        bottomSheetPosition = .relative(isActive ? MapSheetPosition.top.rawValue : MapSheetPosition.middle.rawValue)
                    }
                }
                .padding(.horizontal, 10)
            
            if !searchFieldActive {
                Button(action: { showHelpAlert.toggle() }) {
                    Image(systemName: "info.circle")
                        .opacity(0.8)
                        .font(.system(size: 22, weight: .light))
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
            }
        }
    }
}
