//
//  RoundedButton.swift
//  Jimo
//
//  Created by Gautam Mekkat on 11/7/20.
//

import SwiftUI

struct RoundedButton: View {
    let text: Text
    let action: () -> Void
    let backgroundColor: Color

    var body: some View {
        Button(action: action) {
            text
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(
                    RoundedRectangle(cornerRadius: 100).fill(backgroundColor)
                        .shadow(radius: 3))
        }
    }
}
