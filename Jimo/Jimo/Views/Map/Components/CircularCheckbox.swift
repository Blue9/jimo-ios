//
//  CircularCheckbox.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/31/23.
//

import SwiftUI

struct CircularCheckbox: View {
    var selected: Bool

    var imageName: String {
        selected ? "checkmark.circle.fill" : "circle"
    }

    var body: some View {
        Image(systemName: imageName)
            .font(.system(size: 30, weight: .light))
            .foregroundColor(.blue)
    }
}
