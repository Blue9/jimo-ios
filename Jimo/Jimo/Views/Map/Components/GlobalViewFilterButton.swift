//
//  GlobalViewFilterButton.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/31/23.
//

import SwiftUI

struct GlobalViewFilterButton: View {
    var body: some View {
        ZStack {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(5)
            Circle()
                .stroke(Colors.angularGradient, style: StrokeStyle(lineWidth: 2.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
