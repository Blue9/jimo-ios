//
//  View+navDestination.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/30/23.
//

import SwiftUI

extension View {
    @ViewBuilder func navDestination<Content: View>(isPresented: Binding<Bool>, @ViewBuilder destination: () -> Content) -> some View {
        if #available(iOS 16, *) {
            self.navigationDestination(isPresented: isPresented, destination: destination)
        } else {
            self.background(NavigationLink(isActive: isPresented, destination: destination, label: {}))
        }
    }
}
