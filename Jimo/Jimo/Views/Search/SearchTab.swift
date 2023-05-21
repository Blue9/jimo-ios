//
//  SearchTab.swift
//  Jimo
//
//  Created by Gautam Mekkat on 2/12/23.
//

import SwiftUI

struct SearchTab: View {
    @StateObject private var navigationState = NavigationState()

    var body: some View {
        Navigator(state: navigationState) {
            SearchUsers()
                .trackScreen(.searchTab)
                .ignoresSafeArea(.keyboard, edges: .all)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarColor(UIColor(Color("background")))
        }
    }
}
