//
//  View+navigation.swift
//  Jimo
//
//  Created by Gautam Mekkat on 4/1/22.
//  https://www.fivestars.blog/articles/programmatic-navigation/

import SwiftUI

extension View {
    func navigation<V: Identifiable, Destination: View>(
        item: Binding<V?>,
        destination: @escaping (V?) -> Destination
    ) -> some View {
        self
            .background(NavigationLink(item: item, destination: destination))
            .background(NavigationLink(destination: EmptyView()) { EmptyView() })
            .background(NavigationLink(destination: EmptyView()) { EmptyView() })
        /// Bug in SwiftUI for iOS 14.5, https://developer.apple.com/forums/thread/677333
        /// When you have exactly 2 navigationlinks, the pushed views automatically get popped out. classic apple
    }
}

extension NavigationLink where Label == EmptyView {
    public init?<V: Identifiable>(
        item: Binding<V?>,
        destination: @escaping (V?) -> Destination
    ) {
        let isActive: Binding<Bool> = Binding(
            get: { item.wrappedValue != nil },
            set: { value in
                // There's shouldn't be a way for SwiftUI to set `true` here.
                if !value {
                    item.wrappedValue = nil
                }
            }
        )
        
        self.init(
            destination: destination(item.wrappedValue),
            isActive: isActive,
            label: { EmptyView() }
        )
    }
}
