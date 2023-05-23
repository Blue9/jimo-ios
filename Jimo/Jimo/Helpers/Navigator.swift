//
//  Navigator.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/30/23.
//

import SwiftUI
import NavigationBackport

struct Navigator<Content>: View where Content: View {
    @ObservedObject var state: NavigationState
    var content: () -> Content

    var body: some View {
        NBNavigationStack(path: $state.path) {
            content()
                .nbNavigationDestination(for: NavDestination.self, destination: \.view)
        }.environmentObject(state)
    }
}

// Useful for easier styling using toolbars and navigation title
struct FakeNavigator<Content>: View where Content: View {
    var content: () -> Content

    var body: some View {
        NBNavigationStack(root: content)
    }
}
