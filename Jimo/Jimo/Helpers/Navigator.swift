//
//  Navigator.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/30/23.
//

import SwiftUI

// https://developer.apple.com/forums/thread/716310
struct Navigator<Content>: View where Content: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        if #available(iOS 16, *) {
            NavigationStack(root: content)
        } else {
            NavigationView(content: content).navigationViewStyle(.stack)
        }
    }
}
