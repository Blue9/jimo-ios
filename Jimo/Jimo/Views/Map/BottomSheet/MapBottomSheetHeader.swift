//
//  MapBottomSheetHeader.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/22/22.
//

import SwiftUI
import BottomSheet

struct MapBottomSheetHeader: View {
    @ObservedObject var locationSearch: LocationSearch
    @Binding var bottomSheetPosition: BottomSheetPosition
    @Binding var showHelpAlert: Bool
    var searchFieldActive: FocusState<Bool>.Binding
    
    var body: some View {
        HStack {
            MapSearchField(text: $locationSearch.searchQuery, isActive: searchFieldActive, placeholder: "Search places", onCommit: {
                locationSearch.search()
            }).ignoresSafeArea(.keyboard, edges: .all)
            
            if !searchFieldActive.wrappedValue {
                Button(action: { showHelpAlert.toggle() }) {
                    Image(systemName: "info.circle")
                        .opacity(0.8)
                        .font(.system(size: 22))
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
                }
            }
        }
        .padding(.horizontal, 10)
    }
}
