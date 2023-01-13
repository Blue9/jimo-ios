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
    var searchFieldActive: FocusState<Bool>.Binding
    
    var body: some View {
        MapSearchField(text: $locationSearch.searchQuery, isActive: searchFieldActive, placeholder: "Search a place", onCommit: {
            locationSearch.search()
        })
        .ignoresSafeArea(.keyboard, edges: .all)
        .padding(.horizontal, 10)
    }
}
