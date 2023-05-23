//
//  NavigationState.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/20/23.
//

import SwiftUI

class NavigationState: ObservableObject {
    @Published var path: [NavDestination] = []

    func push(_ dest: NavDestination) {
        path.append(dest)
    }
}
