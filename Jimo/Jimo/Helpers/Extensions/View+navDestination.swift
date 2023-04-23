//
//  View+navDestination.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/30/23.
//

import SwiftUI

extension View {
    @ViewBuilder
    func navDestination<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder destination: () -> Content
    ) -> some View {
        if #available(iOS 16, *) {
            // App is freezing when using this type of navigation link, idk why, it didn't used to
            // self.navigationDestination(isPresented: isPresented, destination: destination)
            self.background(NavigationLink(isActive: isPresented, destination: destination, label: {}))
        } else {
            self.background(NavigationLink(isActive: isPresented, destination: destination, label: {}))
        }
    }
}
