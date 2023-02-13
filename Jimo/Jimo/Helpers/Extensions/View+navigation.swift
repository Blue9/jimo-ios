//
//  View+navigation.swift
//  Jimo
//
//  Created by Gautam Mekkat on 4/10/22.
//

import SwiftUI

extension View {
    @ViewBuilder func navigation<D: Hashable, Content: View>(
        destination: Binding<D?>,
        view: () -> Content
    ) -> some View {
        self.navDestination(
            isPresented: Binding(
                get: { destination.wrappedValue != nil },
                set: { value in
                    // There shouldn't be a way for SwiftUI to set `true` here.
                    if !value {
                        destination.wrappedValue = nil
                    }
                }
            ),
            destination: { view() }
        )
    }
}
