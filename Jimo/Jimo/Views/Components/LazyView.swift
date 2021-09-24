//
//  LazyView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 9/22/21.
//

import SwiftUI

struct LazyView<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
    }
}
