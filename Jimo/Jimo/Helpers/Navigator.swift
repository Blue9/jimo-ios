//
//  Navigator.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/30/23.
//

import SwiftUI

// https://developer.apple.com/forums/thread/716310
struct Navigator<Content>: View where Content: View {
    var path: Binding<[AnyHashable]>?
    @ViewBuilder var content: () -> Content

    init(path: Binding<[AnyHashable]>? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.path = path
        self.content = content
    }

    var body: some View {
        if #available(iOS 16, *) {
            if let path = path {
                NavigationStack(path: path, root: content)
            } else {
                NavigationStack(root: content)
            }
        } else {
            NavigationView(content: content).navigationViewStyle(.stack)
        }
    }
}
