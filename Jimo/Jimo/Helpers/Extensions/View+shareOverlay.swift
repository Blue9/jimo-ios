//
//  View+shareOverlay.swift
//  Jimo
//
//  Created by Gautam Mekkat on 5/5/22.
//

import SwiftUI


extension View {
    func shareOverlay(_ shareAction: ShareAction?, isPresented: Binding<Bool>) -> some View {
        return self.background(
            shareAction != nil ? ActivityView(
                shareAction: shareAction!,
                applicationActivities: nil,
                isPresented: isPresented
            ) : nil
        )
    }
}
