//
//  View+navigation.swift
//  Jimo
//
//  Created by Gautam Mekkat on 4/10/22.
//

import SwiftUI

extension View {
    func navigation<V: Hashable, Destination: View>(
        item: Binding<V?>,
        @ViewBuilder destination: @escaping (V?) -> Destination
    ) -> some View {
        self.navDestination(
            isPresented: Binding(
                get: { item.wrappedValue != nil },
                set: { value in
                    // There shouldn't be a way for SwiftUI to set `true` here.
                    if !value {
                        item.wrappedValue = nil
                    }
                }
            ),
            destination: {
                destination(item.wrappedValue)
            }
        )
    }
}

// extension NavigationLink where Label == EmptyView {
//    public init?<V: Identifiable>(
//        item: Binding<V?>,
//        destination: @escaping (V?) -> Destination
//    ) {
//        let isActive: Binding<Bool> = Binding(
//            get: { item.wrappedValue != nil },
//            set: { value in
//                // There shouldn't be a way for SwiftUI to set `true` here.
//                if !value {
//                    item.wrappedValue = nil
//                }
//            }
//        )
//        self.init(
//            destination: destination(item.wrappedValue),
//            isActive: isActive,
//            label: { EmptyView() }
//        )
//    }
// }
//

//
